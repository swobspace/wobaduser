require 'spec_helper'

describe 'LdapSetup' do
  context "with dummy options" do
    before(:each) do
      @ldap_options = {"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}
    end

    it "set ldap options as symbols" do
      ldap = Wobaduser::LDAP.new(ldap_options: @ldap_options)
      ldap.ldap_options.should be_a_kind_of Hash
      opts = ldap.ldap_options
      opts.should include(:host, :base, :port)
      opts.should_not include("host", "base", "port")
    end
  
    it "set ldap options as symbols" do
      ldap = Wobaduser::LDAP.new(ldap_options: @ldap_options)
      ldap.connection.should be_a_kind_of Net::LDAP
    end
  end
end

