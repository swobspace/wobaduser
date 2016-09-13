require 'timeout'
require 'spec_helper'

describe 'LdapSetup' do
  context "with dummy options" do
   let(:ldap_options) {{ "host" => '127.0.0.1', "base" => 'dc=example,dc=com', :port => 3268}}
   let(:ldap) { Wobaduser::LDAP.new(ldap_options: ldap_options, bind: false) }
   let(:filter) { Net::LDAP::Filter.eq("userprincipalname", "doesnotexist") }

    it "set ldap options as symbols" do
      expect(ldap.ldap_options).to be_a_kind_of Hash
      opts = ldap.ldap_options
      expect(opts).to include(:host, :base, :port)
      expect(opts).not_to include("host", "base", "port")
    end
  
    it { expect(ldap).to respond_to(:search) }
    it { expect(ldap).to respond_to(:errors) }
    it { expect(ldap).not_to respond_to(:connection) }
    it { expect(ldap).not_to respond_to(:connected?) }

    it "ldap search doesn't raise an error" do
      expect{ 
        ldap.search(filter: filter) 
      }.not_to raise_error
    end

    it "ldap search delivers some errors" do
      ldap.search(filter: filter)
      expect(ldap.errors.any?).to be_truthy
    end
    
    it "connect to a existing host without ldap server should get connection refused" do
      ldap = nil
      Wobaduser.timeout = 2
      expect {
        ldap = Wobaduser::LDAP.new(ldap_options: ldap_options, bind: true)
      }.not_to raise_error
      expect(ldap.errors.any?).to be_truthy
      expect(ldap.errors.join(" ")).to match /Connection refused/
    end

    it "connect to a nonexistent host should timeout" do
      Wobaduser.timeout = 2
      ldap_options['host'] = '1.2.3.4'
      ldap = Wobaduser::LDAP.new(ldap_options: ldap_options, bind: true)
      expect(ldap.errors.join(" ")).to match /Timeout: could not bind to server/
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
      expect(ldap.errors.any?).to be_falsey
      expect(entry).to be_a_kind_of Net::LDAP::Entry
      expect(entry).to respond_to(:userprincipalname)
      expect(entry.userprincipalname).to include(ENV['USERPRINCIPALNAME'])
    end
  end

end
