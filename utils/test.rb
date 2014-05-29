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

ldap = Wobaduser::LDAP.new(ldap_options: LDAP_OPTIONS)

# -- get user dn
user_filter = Net::LDAP::Filter.equals("userprincipalname", ENV['USERPRINCIPALNAME'])
user = ldap.search(filter: user_filter).first
puts user.dn

# -- get all groups
filter = Net::LDAP::Filter.present("cn") & Net::LDAP::Filter.eq("objectClass", "group") &
         Net::LDAP::Filter.ex("member:1.2.840.113556.1.4.1941", user.dn)

all_groups = ldap.search(filter: filter)
all_groups.each do |g|
  puts g.cn
end

