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
# user = Wobaduser::User.new(ldap, filter, attributes: ATTRIBUTES)
user = Wobaduser::User.new(ldap, filter)

unless user.error.nil?
  puts user.error.inspect
  exit 1
end

if user.valid?
  puts "#{ENV['USERPRINCIPALNAME']}"
else
  puts "#{ENV['USERPRINCIPALNAME']} is no valid userprincipalname"
  exit 1
end

Wobaduser::User::ATTR_SV.each do |key,val|
  puts "#{key} : #{user.send(key)}" unless user.send(key).blank?
end
Wobaduser::User::ATTR_MV.each do |key,val|
  puts "#{key} : #{user.send(key)}" unless user.send(key).blank?
end
puts "---"
puts user.all_groups.inspect
