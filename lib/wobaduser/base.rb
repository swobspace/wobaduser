# additional copyright info:
# the metaprogramming for generate_single_value_readers and
# generate_multi_value_readers was published 2008 by Ernie Miller on
# http://erniemiller.org/2008/04/04/simplified-active-directory-authentication/
# with an excellent explanation.
#
require 'immutable-struct'

module Wobaduser
  class Base
    SearchResult = ImmutableStruct.new( :success?, :errors, :entries )

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

    attr_reader :errors, :entry

    # Create an new Wobaduser object
    # not to be intended to call directly, but possible. Better to use 
    # Wobaduser::User.new or Wobaduser::Group.new. There are to modes:
    # 1) use Wobaduser::LDAP + LDAP-Filter
    # 2) use a retrieved LDAP entry, i.e. used in Wobaduser::Base.search
    # 
    # [+:entry+]	ldap entry
    # [+:ldap+]		instance of Wobaduser::LDAP
    # [+:filter+]	ldap filter (as string, *not* as Net::LDAP::Filter)
    # [+:ldap_options+]	additional ldap options for search
    # 
    # :entry and (:ldap, :filter) are mutually exclusive
    # 
    def initialize(options = {})
      options.symbolize_keys!
      keys = options.keys
      if keys.include?(:entry) && (keys & [:ldap, :filter, :ldap_options]).any?
        raise ArgumentError, ":entry and one of (:ldap, :filter, :ldap_options) are mutually exclusive!"
      end
      reset_errors
      get_ldap_entry(options)
      unless entry.nil?
        self.class.class_eval do
          generate_single_value_readers
          generate_multi_value_readers
        end
      end
    end

    def self.search(options = {})
      search = search_ldap_entries(options)
      if search.success?
        entries = search.entries.map {|entry| self.new(entry: entry)}
        result = SearchResult.new(success: true, errors: [], entries: entries)
      else
        result = SearchResult.new(success: false, errors: search.errors, entries: [])
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

    def self.search_ldap_entries(options)
      ldap = options.fetch(:ldap) || raise "ldap connection not yet available"
      filter = options.fetch(:filter)
      ldap_options = options.fetch(:ldap_options, {}).
                       merge(filter: build_filter(filter))
      entries = ldap.search(ldap_options)
      if ldap.errors.any?
        result = SearchResult.new(success: false, errors: ldap.errors, entries: [])
      else
        result = SearchResult.new(success: true, errors: [], entries: entries)
      end
    end

    def self.build_filter(filter)
      unless filter.kind_of? Net::LDAP::Filter
        filter = Net::LDAP::Filter.construct(filter)
      end
      filter & self.filter
    end

  protected

    def add_error(message)
      @errors << message
    end

    def reset_errors
      @errors = []
    end

  private

    def get_ldap_entry(options)
      if options.keys.include?(:entry)
        @entry = options.fetch(:entry)
        reset_errors
      else
        result = Wobaduser::Base.search_ldap_entries(options)
        if result.success?
          @entry = result.entries.first
        else
          add_error(result.errors.join(", "))
          @entry = nil
        end
      end
    end

  end
end
