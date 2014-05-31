# additional copyright info:
# the metaprogramming for generate_single_value_readers and
# generate_multi_value_readers was published 2008 by Ernie Miller on
# http://erniemiller.org/2008/04/04/simplified-active-directory-authentication/
# with an excellent explanation.
#
module Wobaduser
  class Base

    ###################################################################
    # ATTR_SV is for single valued attributes only. result is a string.
    # ATTR_MV is for multi valued attributes. result is an array.
    # Concrete values should be set in subclasses. See Wobaduser::User 
    # for an example.
    #
    ATTR_SV={}
    ATTR_MV={}
    #
    ###################################################################

    attr_reader :error, :entry

    # Wobaduser::Base.new(Wobaduser::LDAP.new, filter: filter, options = other_ldap_options)
    # 
    def initialize(ldap, filter, options = {})
      options.symbolize_keys!
      options = options.merge(filter: build_filter(filter))
      @entry = ldap.search(options).first
      @error = ldap.error
      @ldap  = ldap
      unless @entry.nil?
        self.class.class_eval do
          generate_single_value_readers
          generate_multi_value_readers
        end
      end
    end

    def self.filter
      Net::LDAP::Filter.present('objectClass')
    end

    def valid?
      @entry.kind_of? Net::LDAP::Entry
    end

    protected

    #
    # method generator for single value attributes defined in ATTR_SV
    #
    def self.generate_single_value_readers
      return if ATTR_SV.nil?
      self::ATTR_SV.each_pair do |k, v|
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

    #
    # method generator for multi value attributes defined in ATTR_MV
    #
    def self.generate_multi_value_readers
      return if ATTR_SV.nil?
      self::ATTR_MV.each_pair do |k, v|
	val, block = Array(v)
	define_method(k) do
	  if @entry.attribute_names.include?(val)
	    if block.is_a?(Proc)
	      finals = @entry.send(val).collect(&block)
	    else
	      finals = @entry.send(val)
	    end
	    finals = finals.map{|v| v.is_a?(String) ? v.to_s.force_encoding('UTF-8') : v } if finals.is_a? Array   
	    return finals.compact
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
