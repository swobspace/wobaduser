require 'timeout'
module Wobaduser
  class LDAP
    attr_reader :ldap_options

    # Wobaduser::Ldap.new({ldap_options: {}})
    # for possible ldap options see Net::LDAP::new
    #
    def initialize(options = {})
      options.symbolize_keys!
      @ldap_options = options.fetch(:ldap_options).symbolize_keys!
    end

    def connection(options ={})
      options.symbolize_keys!
      unless @connection
        @connection = Net::LDAP.new(@ldap_options)
        if options.fetch(:bind, true)
          Timeout::timeout(Wobaduser.timeout) { 
            @connection.bind
          }
        end
      end
      @connection
    end

  end
end
