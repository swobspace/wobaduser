require 'timeout'
require 'spec_helper'

describe 'LdapSetup' do
  context "with dummy options" do
    before(:each) do
      @ldap_options = {"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}
      @ldap = Wobaduser::LDAP.new(ldap_options: @ldap_options)
    end

    it "set ldap options as symbols" do
      @ldap.ldap_options.should be_a_kind_of Hash
      opts = @ldap.ldap_options
      opts.should include(:host, :base, :port)
      opts.should_not include("host", "base", "port")
    end
  
    it "Wobaduser::LDAP#connection is a kind of Net::LDAP" do
      @ldap.connection(bind: false).should be_a_kind_of Net::LDAP
    end

    it "connect to a nonexistent host should timeout" do
      Wobaduser.timeout = 2
      Timeout::timeout(Wobaduser.timeout + 1) do
        lambda {
          @ldap.connection
        }.should raise_error(Timeout::Error)
      end
    end
  end
end

