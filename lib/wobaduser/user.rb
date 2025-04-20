module Wobaduser
  class User < Base
    AD_EPOCH      = 116_444_736_000_000_000
    AD_MULTIPLIER = 10_000_000

    ########################################################################
    # ATTR_SV is for single valued attributes only. Generated readers will
    # convert the value to a string before returning or calling your Proc.

    ATTR_SV = {
      # method name         ldap attribute
      :username           => :userprincipalname,
      :userprincipalname  => :userprincipalname,
      :givenname          => :givenname,
      :sn                 => :sn,
      :cn                 => :cn,
      :dn                 => :dn,
      :displayname        => :displayname,
      :mail               => :mail,
      :title              => :title,
      :telephonenumber    => :telephonenumber,
      :facsimiletelephonenumber => :facsimiletelephonenumber,
      :mobile             => :mobile,
      :description        => :description,
      :department         => :department,
      :company            => :company,
      :postalcode         => :postalcode,
      :l                  => :l,
      :streetaddress      => :streetaddress,
      :samaccountname     => :samaccountname,
      :primarygroupid     => :primarygroupid,
      :extensionattribute15     => :extensionattribute15,
      :guid               => [ :objectguid, Proc.new {|p| Base64.encode64(p).chomp } ],
      :useraccountcontrol => :useraccountcontrol,
      :disabled => [ :useraccountcontrol, Proc.new {|c| (c.to_i & 2) != 0 } ],
      :accountexpires     => :accountexpires,
      :expirationdate     => [ :accountexpires, Proc.new {|t| Time.at((t.to_i - AD_EPOCH) / AD_MULTIPLIER).to_date } ]

    }

    # ATTR_MV is for multi-valued attributes. Generated readers will always
    # return an array.

    ATTR_MV = {
      # method name         ldap attribute
      :members     => :member,
      :objectclass => :objectclass,
      :memberof    => :memberof,
      :groups      => [ :memberof,
                      # Get the simplified name of first-level groups.
                      # TODO: Handle escaped special characters
                      Proc.new {|g| g.sub(/.*?CN=(.*?),.*/, '\1')} ],
      # :mailaliases => [ :proxyAddresses, Proc.new{|p| p.lowercase.gsub(/\Asmtp:/,'')}]
      :mailaliases => [ :proxyaddresses, Proc.new {|p|
                                           p = p.downcase
                                           next unless p=~ /\Asmtp:/
                                           p.gsub(/\Asmtp:/, '')
                                         }],
    }
    #
    ########################################################################

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
      @ldap.search(filter: filter, attributes: ['cn']).map(&:cn).flatten.map(&:as_utf8)
    end

    def is_valid?
      !disabled && !expired?
    end

    def expired?
      !expirationdate.to_date.nil? && (expirationdate.to_date < Date.current)
    end
  end
end

