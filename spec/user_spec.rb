require 'timeout'
require 'spec_helper'

describe 'User' do
  context "with different options on #new" do
    let(:ldap_options) {{"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}}
    let(:ldap)  { Wobaduser::LDAP.new(ldap_options: ldap_options) }
    let(:entry) { instance_double("Net::LDAP::Entry") }
    let(:filter) { Net::LDAP::Filter.eq("userprincipalname", "doesnotexist") }

    it ":entry does not raise an ArgumentError" do
      expect {
        Wobaduser::User.new(entry: entry)
      }.not_to raise_error
    end

    it ":entry does not raise an ArgumentError" do
      expect {
        Wobaduser::User.new(ldap: ldap, filter: filter)
      }.to raise_error(Net::LDAP::Error)
    end

    [:ldap, :filter, :ldap_options].each do |option|
      it ":entry and #{option} raises an ArgumentError" do
        expect {
          Wobaduser::User.new(entry: entry, option => nil)
        }.to raise_error(ArgumentError)
      end
    end
  end

  context "with dummy options" do
    let(:ldap_options) {{"host" => '1.2.3.4', "base" => 'dc=example,dc=com', :port => 3268}}
    let(:ldap) {Wobaduser::LDAP.new(ldap_options: ldap_options, bind: false)}

    it "breaks something" do
      filter = Net::LDAP::Filter.eq("userprincipalname", "doesnotexist")
      expect { user = Wobaduser::User.new(ldap: ldap, filter: filter) }.to raise_error(Net::LDAP::Error)
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
	user = Wobaduser::User.new(ldap: ldap, filter: filter)
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
	user = Wobaduser::User.new(ldap: ldap, filter: filter)
	expect(user.valid?).to be_falsey
      end
    end

    describe "::search" do
      let(:users) { Wobaduser::User.search(ldap: ldap, filter: filter) }

      context "search for sn" do
        let(:filter) {Net::LDAP::Filter.eq("sn", ENV['LDAP_SEARCH_SN'])}

	it { expect(users).to be_a_kind_of Array }
	it { expect(users.map {|u| u.userprincipalname}).to include( 
	     ENV['USERPRINCIPALNAME3'], ENV['USERPRINCIPALNAME2']) }
      end

      context "search for givenname" do
        let(:filter) {Net::LDAP::Filter.eq("givenname", ENV['LDAP_SEARCH_GIVENNAME'])}

	it { expect(users).to be_a_kind_of Array }
	it { expect(users.map {|u| u.userprincipalname}).to include( 
	     ENV['USERPRINCIPALNAME3'], ENV['USERPRINCIPALNAME2']) }
      end

      context "search for mail" do
        let(:filter) {Net::LDAP::Filter.eq("mail", ENV['LDAP_SEARCH_EMAIL'])}

	it { expect(users).to be_a_kind_of Array }
	it { expect(users.map {|u| u.userprincipalname}).to include( 
	     ENV['USERPRINCIPALNAME2']) }
      end
    end
  end
end
