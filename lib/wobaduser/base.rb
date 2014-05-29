module Wobaduser
  class Base
    attr_reader :error, :entry

    # Wobaduser::Base.new(Wobaduser::LDAP.new, filter: filter, options = other_ldap_options)
    # 
    def initialize(ldap, filter, options = {})
      options.symbolize_keys!
      options = options.merge(filter: build_filter(filter))
      @entry = ldap.search(options).first
      @error = ldap.error
      @ldap  = ldap
    end

    def self.filter
      Net::LDAP::Filter.present('objectClass')
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

