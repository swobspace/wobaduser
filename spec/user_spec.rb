require 'timeout'
require 'spec_helper'

describe 'User' do
  context "with dummy options" do
    before(:each) do
      @ldap_options = {"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}
      @ldap = Wobaduser::LDAP.new(ldap_options: @ldap_options, bind: false)
    end

    it "breaks something" do
      @filter = Net::LDAP::Filter.eq("userprincipalname", "doesnotexist")
      expect { user = Wobaduser::User.new(@ldap, @filter) }.to raise_error(RuntimeError)
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
    
    context "and valid USERPRINCIPALNAME" do
      before(:each) do
	@filter = Net::LDAP::Filter.eq("userprincipalname", ENV['USERPRINCIPALNAME'])
      end

      it "valid user should respond to various attribute methods" do
	user = Wobaduser::User.new(@ldap, @filter)
	user.valid?.should be_true
	user.should respond_to(:userprincipalname)
	user.userprincipalname.should include(ENV['USERPRINCIPALNAME'])
	Wobaduser::User::ATTR_SV.each do |key,value|
	  user.send(key).should be_a_kind_of String unless key == :is_valid?
	end
	Wobaduser::User::ATTR_MV.each do |key,value|
	  user.send(key).should be_a_kind_of Array
	end
      end
    end

    context "and invalid USERPRINCIPALNAME" do
      before(:each) do
	@filter = Net::LDAP::Filter.eq("userprincipalname", "doesnotexist")
      end

      it "valid user should respond to various attribute methods" do
	user = Wobaduser::User.new(@ldap, @filter)
	user.valid?.should be_false
      end
    end
  end
end
