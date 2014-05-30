# Copyright info:
# the metaprogramming for generate_single_value_readers and
# generate_multi_value_readers was published 2008 by Ernie Miller on
# http://erniemiller.org/2008/04/04/simplified-active-directory-authentication/
# with an excellent explanation.
#
module Wobaduser
  class Base

    ########################################################################
    # ATTR_SV is for single valued attributes only. Generated readers will
    # convert the value to a string before returning or calling your Proc.
    ATTR_SV = { 
      :username         => :userprincipalname,
      :givenname        => :givenname,
      :sn               => :sn,
      :cn               => :cn,
      :dn               => :dn,
      :displayname      => :displayname,
      :mail             => :mail,
      :title            => :title,
      :telephonenumber  => :telephonenumber,
      :facsimiletelephonenumber => :facsimiletelephonenumber,
      :mobile           => :mobile,
      :description      => :description,
      :department       => :department,
      :company          => :company,
      :postalcode       => :postalcode,
      :l                => :l,
      :streetaddress    => :streetaddress,
      :samaccountname   => :samaccountname,
      :primarygroupid   => :primarygroupid,
      :guid             => [ :objectguid, Proc.new {|p| Base64.encode64(p).chomp } ],
      :useraccountcontrol => :useraccountcontrol,
      :is_valid? => [ :useraccountcontrol, Proc.new {|c| (c.to_i & 2) == 0 } ],
    }

    # ATTR_MV is for multi-valued attributes. Generated readers will always 
    # return an array.
    ATTR_MV = { 
      :members     => :member,
      :objectclass => :objectclass,
      :groups      => [ :memberof,
                      # Get the simplified name of first-level groups.
                      # TODO: Handle escaped special characters
                      Proc.new {|g| g.sub(/.*?CN=(.*?),.*/, '\1')} ]
    }
    ########################################################################

    attr_reader :error, :entry

    # Wobaduser::Base.new(Wobaduser::LDAP.new, filter: filter, options = other_ldap_options)
    # 
    def initialize(ldap, filter, options = {})
      options.symbolize_keys!
      options = options.merge(filter: build_filter(filter))
      @entry = ldap.search(options).first
      @error = ldap.error
      @ldap  = ldap
      self.class.class_eval do
        generate_single_value_readers
        generate_multi_value_readers
      end
    end

    def self.filter
      Net::LDAP::Filter.present('objectClass')
    end

    protected

    def self.generate_single_value_readers
      ATTR_SV.each_pair do |k, v|
	val, block = Array(v)
	define_method(k) do
	  if @entry.attribute_names.include?(val)
	    attribute = @entry.send(val)
	    attribute = attribute.first if attribute.is_a? Array
	    if block.is_a?(Proc)
	      final = block[attribute.to_s]
	    else
	      final = attribute.to_s
	    end
	    final = final.force_encoding('UTF-8') if final.is_a? String
	    return final
	  else
	    return ''
	  end
	end
      end
    end

    def self.generate_multi_value_readers
      ATTR_MV.each_pair do |k, v|
	val, block = Array(v)
	define_method(k) do
	  if @entry.attribute_names.include?(val)
	    if block.is_a?(Proc)
	      finals = @entry.send(val).collect(&block)
	    else
	      finals = @entry.send(val)
	    end
	    finals = finals.map{|v| v.is_a?(String) ? v.to_s.force_encoding('UTF-8') : v } if finals.is_a? Array   
	    return finals
	  else
	    return []
	  end
	end
      end
    end

    private

    def build_filter(filter)
      unless filter.kind_of? Net::LDAP::Filter
        filter = Net::LDAP::Filter.construct(filter)
      end
      filter & self.filter
    end
  end
end
