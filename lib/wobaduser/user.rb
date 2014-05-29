module Wobaduser
  class User < Base
    def filter(valid = false)
      filter = Net::LDAP::Filter.eq('objectClass', 'user')
      if valid
        filter & ~(Net::LDAP::Filter.ex('UserAccountControl:1.2.840.113556.1.4.803', 2))
      else
        filter
      end
    end

    def all_groups
      filter = Net::LDAP::Filter.present("cn") & Net::LDAP::Filter.eq("objectClass", "group") &
         Net::LDAP::Filter.ex("member:1.2.840.113556.1.4.1941", @entry.dn)
      @ldap.search(filter: filter, attributes: ['cn']).map(&:cn).flatten
    end
  end
end

