require 'timeout'
require 'spec_helper'

describe 'LdapSetup' do
  context "with dummy options" do
    before(:each) do
      @ldap_options = {"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}
      @ldap = Wobaduser::LDAP.new(ldap_options: @ldap_options, bind: false)
    end

    it "set ldap options as symbols" do
      @ldap.ldap_options.should be_a_kind_of Hash
      opts = @ldap.ldap_options
      opts.should include(:host, :base, :port)
      opts.should_not include("host", "base", "port")
    end
  
    it "Wobaduser::LDAP should respond to #search" do
      @ldap.should respond_to(:search)
    end

    it "connect to a nonexistent host should timeout" do
      Wobaduser.timeout = 2
      Timeout::timeout(Wobaduser.timeout + 1) do
        lambda {
          Wobaduser::LDAP.new(ldap_options: @ldap_options, bind: true)
        }.should raise_error(Timeout::Error)
      end
    end
  end

  context "with real environment" do
    before(:each) do
      @ldap_options = {
        host: ENV['LDAP_HOST'], 
        base: ENV['LDAP_BASE'],
  	port: ENV['LDAP_PORT'],
  	auth: {
    	  method: :simple,
    	  username: ENV['LDAP_USER'],
    	  password: ENV['LDAP_PASSWD'],
  	}
      }
      @ldap = Wobaduser::LDAP.new(ldap_options: @ldap_options, bind: true)
    end

    it "Wobaduser::LDAP should delegate search" do
      @ldap.should respond_to(:search)
    end

    it "search should return Net::LDAP::Entries" do
      filter = Net::LDAP::Filter.eq("userprincipalname", ENV['USERPRINCIPALNAME'])
      entry = @ldap.search(filter: filter).first
      entry.should be_a_kind_of Net::LDAP::Entry
      entry.should respond_to(:userprincipalname)
      entry.userprincipalname.should include(ENV['USERPRINCIPALNAME'])
    end
  end

end

