#!/usr/bin/env ruby

require "bundler/setup"
Bundler.setup

require 'wobaduser'
require 'dotenv'

# require_relative "../lib/wobaduser"

Dotenv.load!( File.expand_path(__FILE__ + '/../../spec/.localenv'),
              File.expand_path(__FILE__ + '/../../spec/.env'))

LDAP_OPTIONS = {
  host: ENV['LDAP_HOST'],
  base: ENV['LDAP_BASE'],
  port: ENV['LDAP_PORT'],
  auth: {
    method: :simple,
    username: ENV['LDAP_USER'],
    password: ENV['LDAP_PASSWD'],
  }
}
ATTRIBUTES = [ "cn", "dn", "sn", "givenname", "mail", "proxyAddresses" ]

filter = Net::LDAP::Filter.eq("userprincipalname", ENV['USERPRINCIPALNAME'])

ldap = Wobaduser::LDAP.new(ldap_options: LDAP_OPTIONS)
user = Wobaduser::User.new(ldap, filter, attributes: ATTRIBUTES)
# user = Wobaduser::User.new(ldap, filter)

puts user.cn

puts user.all_groups.inspect
