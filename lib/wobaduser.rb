require "wobaduser/version"
require 'net/ldap'
require 'active_support/core_ext/module'
require 'active_support/core_ext/hash'

module Wobaduser
  autoload :LDAP, 'wobaduser/ldap'
  autoload :Base, 'wobaduser/base'
  autoload :User, 'wobaduser/user'

  def self.setup
    yield self
  end

  # timeout for ldap connections
  mattr_accessor :timeout
  @@timeout = 10
end
