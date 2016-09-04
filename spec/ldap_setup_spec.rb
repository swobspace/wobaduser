require 'timeout'
require 'spec_helper'

describe 'LdapSetup' do
  context "with dummy options" do
   let(:ldap_options) {{ "host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}}
   let(:ldap) { Wobaduser::LDAP.new(ldap_options: ldap_options, bind: false) }

    it "set ldap options as symbols" do
      expect(ldap.ldap_options).to be_a_kind_of Hash
      opts = ldap.ldap_options
      expect(opts).to include(:host, :base, :port)
      expect(opts).not_to include("host", "base", "port")
    end
  
    it "Wobaduser::LDAP should respond to #search" do
      expect(ldap).to respond_to(:search)
    end

    it "connect to a nonexistent host should timeout" do
      Wobaduser.timeout = 2
      Timeout::timeout(Wobaduser.timeout + 1) do
        expect {
          Wobaduser::LDAP.new(ldap_options: ldap_options, bind: true)
        }.to raise_error(Timeout::Error)
      end
    end
  end

  context "with real environment" do
    let(:ldap_options) { {
        host: ENV['LDAP_HOST'], 
        base: ENV['LDAP_BASE'],
  	port: ENV['LDAP_PORT'],
  	auth: {
    	  method: :simple,
    	  username: ENV['LDAP_USER'],
    	  password: ENV['LDAP_PASSWD'],
  	}
      } }
    let(:ldap) { Wobaduser::LDAP.new(ldap_options: ldap_options, bind: true) }

    it "Wobaduser::LDAP should delegate search" do
      expect(ldap).to respond_to(:search)
    end

    it "search should return Net::LDAP::Entries" do
      filter = Net::LDAP::Filter.eq("userprincipalname", ENV['USERPRINCIPALNAME'])
      entry = ldap.search(filter: filter).first
      expect(entry).to be_a_kind_of Net::LDAP::Entry
      expect(entry).to respond_to(:userprincipalname)
      expect(entry.userprincipalname).to include(ENV['USERPRINCIPALNAME'])
    end
  end

end

