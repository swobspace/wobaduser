require 'timeout'
require 'net/ldap'

module Wobaduser
  class LDAP
    attr_reader :ldap_options, :connection

    # Wobaduser::Ldap.new({ldap_options: {}})
    # for possible ldap options see Net::LDAP::new
    #
    def initialize(options = {})
      options.symbolize_keys!
      @ldap_options = options.fetch(:ldap_options).symbolize_keys!
      do_bind = options.fetch(:bind, true)
      connection(ldap_options: @ldap_options, bind: do_bind)
    end

    def search(options = {})
      options.symbolize_keys!
      result = connection.search(options)
    end

    def error
      (connection.get_operation_result.code == 0) ? nil : connection.get_operation_result
    end

    protected

    def connection(options ={})
      return @connection unless @connection.nil?
      options.symbolize_keys!
      @connection = Net::LDAP.new(options.fetch(:ldap_options))
      if options.fetch(:bind, true)
        Timeout::timeout(Wobaduser.timeout) { 
          @connection.bind
        }
      end
      @connection
    end

  end
end
