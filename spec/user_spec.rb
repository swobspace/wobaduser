require 'timeout'
require 'spec_helper'

describe 'User' do
  context "with dummy options" do
    let(:ldap_options) {{"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}}
    let(:ldap) {Wobaduser::LDAP.new(ldap_options: ldap_options, bind: false)}

    it "breaks something" do
      filter = Net::LDAP::Filter.eq("userprincipalname", "doesnotexist")
      expect { user = Wobaduser::User.new(ldap, filter) }.to raise_error(RuntimeError)
    end
  end

  context "with real environment" do
    let(:ldap_options) {{
        host: ENV['LDAP_HOST'], 
        base: ENV['LDAP_BASE'],
  	port: ENV['LDAP_PORT'],
  	auth: {
    	  method: :simple,
    	  username: ENV['LDAP_USER'],
    	  password: ENV['LDAP_PASSWD'],
  	}
      }}
    let(:ldap) {Wobaduser::LDAP.new(ldap_options: ldap_options, bind: true)}
    
    context "and valid USERPRINCIPALNAME" do
      let(:filter) {Net::LDAP::Filter.eq("userprincipalname", ENV['USERPRINCIPALNAME'])}

      it "valid user should respond to various attribute methods" do
	user = Wobaduser::User.new(ldap, filter)
	expect(user.valid?).to be_truthy
	expect(user).to respond_to(:userprincipalname)
	expect(user.userprincipalname).to include(ENV['USERPRINCIPALNAME'])
	Wobaduser::User::ATTR_SV.each do |key,value|
	  expect(user.send(key)).to be_a_kind_of String unless key == :is_valid?
	end
	Wobaduser::User::ATTR_MV.each do |key,value|
	  expect(user.send(key)).to be_a_kind_of Array
	end
      end
    end

    context "and invalid USERPRINCIPALNAME" do
      let(:filter) {Net::LDAP::Filter.eq("userprincipalname", "doesnotexist")}

      it "valid user should respond to various attribute methods" do
	user = Wobaduser::User.new(ldap, filter)
	expect(user.valid?).to be_falsey
      end
    end
  end
end
