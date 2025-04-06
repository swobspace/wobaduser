require 'timeout'
require 'net/ldap'

module Wobaduser
  class LDAP
    attr_reader :ldap_options, :errors

    # Wobaduser::LDAP.new({ldap_options: {}, bind: true})
    #
    # [+:ldap_options+]   for possible ldap options see Net::LDAP::new
    # [+:bind+]           true: bind on initialize, false: bind on later operations
    #
    def initialize(options = {})
      options.symbolize_keys!
      reset_errors
      @ldap_options = options.fetch(:ldap_options).symbolize_keys!
      do_bind = options.fetch(:bind, true)
      connection(ldap_options: @ldap_options, bind: do_bind)
    end

    # execute ldap search operation
    #
    # for possible ldap options see Net::LDAP#search
    #
    def search(options = {})
      reset_errors
      options.symbolize_keys!
      begin
	result = connection.search(options)
	add_error(operation_error)
      rescue => e
	result = []
	add_error(e.message)
      end
      result
    end

    # returns last ldap operation error, if any
    #
    def operation_error
      (connection.get_operation_result.code == 0) ? nil : connection.get_operation_result
    end
 
  private
    attr_reader :connection

    def add_error(message)
      @errors << message
    end

    def reset_errors
      @errors = []
    end

    def connected?
      !!@connected
    end

    def connection(options ={})
      return @connection if @connected
      @connected = false
      reset_errors
      options.symbolize_keys!
      @connection ||= Net::LDAP.new(options.fetch(:ldap_options))
      if options.fetch(:bind, true)
	begin
	  Timeout::timeout(Wobaduser.timeout) { 
	    if @connection.bind
	      @connected = true
	    else
              add_error(operation_error)
	    end
	  }
        rescue Timeout::Error => e
          add_error("Timeout: could not bind to server within #{Wobaduser.timeout} seconds")
        rescue Net::LDAP::Error => e
          add_error(e.message)
        rescue => e
          add_error(e.message)
        end
      end
      @connection
    end

  end
end
