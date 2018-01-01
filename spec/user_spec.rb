require 'timeout'
require 'spec_helper'

describe 'User' do
  context "with different options on #new" do
    let(:ldap_options) {{"host" => '127.0.0.1', "base" => 'dc=example,dc=com', :port => 3268}}
    let(:ldap)  { Wobaduser::LDAP.new(ldap_options: ldap_options) }
    let(:entry) { instance_double("Net::LDAP::Entry") }
    let(:filter) { Net::LDAP::Filter.eq("userprincipalname", "doesnotexist") }

    it ":entry does not raise an ArgumentError" do
      expect {
        Wobaduser::User.new(entry: entry)
      }.not_to raise_error
    end

    it ":ldap + :filter does not raise an ArgumentError" do
      expect {
        Wobaduser::User.new(ldap: ldap, filter: filter)
      }.not_to raise_error
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
    let(:ldap_options) {{"host" => '127.0.0.1', "base" => 'dc=example,dc=com', :port => 3268}}
    let(:ldap) { Wobaduser::LDAP.new(ldap_options: ldap_options, bind: false) }
    let(:user) { Wobaduser::User.new(ldap: ldap, filter: filter) }
    let(:filter) { Net::LDAP::Filter.eq("userprincipalname", "doesnotexist") }

    it { expect(ldap.errors.any?).to be_falsey }

    it { expect { user }.not_to raise_error }
    it { expect(user.errors.any?).to be_truthy }
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
      let(:entries) { Wobaduser::User.search(ldap: ldap, filter: filter) }
      let(:users)   { entries.entries }

      context "search for sn" do
        let(:filter) {Net::LDAP::Filter.eq("sn", "#{ENV['LDAP_SEARCH_SN']}*")}

        it { expect(entries.success?).to be_truthy }
	it { expect(users).to be_a_kind_of Array }
	it { expect(users.map {|u| u.userprincipalname}).to include( 
	     ENV['USERPRINCIPALNAME3'], ENV['USERPRINCIPALNAME2']) }
      end

      context "search for givenname" do
        let(:filter) {Net::LDAP::Filter.eq("givenname", ENV['LDAP_SEARCH_GIVENNAME'])}

        it { expect(entries.success?).to be_truthy }
	it { expect(users).to be_a_kind_of Array }
	it { expect(users.map {|u| u.userprincipalname}).to include( 
	     ENV['USERPRINCIPALNAME3'], ENV['USERPRINCIPALNAME2']) }
      end

      context "search for mail" do
        let(:filter) {Net::LDAP::Filter.eq("mail", ENV['LDAP_SEARCH_EMAIL'])}

        it { expect(entries.success?).to be_truthy }
	it { expect(users).to be_a_kind_of Array }
	it { expect(users.map {|u| u.userprincipalname}).to include( 
	     ENV['USERPRINCIPALNAME2']) }
      end

      context "with invalid filter" do
        let(:filter) {"bla"}
        let(:entries) { Wobaduser::User.search(ldap: ldap, filter: filter) }

        it "raises a FilterSyntaxInvalidError" do
          expect { 
            entries.success?
          }.to raise_error(Net::LDAP::FilterSyntaxInvalidError)
        end
      end
    end
  end
end
