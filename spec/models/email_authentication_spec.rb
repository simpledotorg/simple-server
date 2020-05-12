require 'rails_helper'

RSpec.describe EmailAuthentication, type: :model do
  WEAK_PASSWORD_ERROR = "is too weak. We recommend a passphrase made up of at least four randomly choosen words. For example 'logic finite eager ratio'"

  describe 'Associations' do
    it { should have_one(:user_authentication) }
    it { should have_one(:user).through(:user_authentication) }
  end

  it "should require a non blank password" do
    auth = build(:email_authentication, password: "")
    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to eq ["can't be blank", WEAK_PASSWORD_ERROR]
  end

  it "should require a strong password" do
    auth = build(:email_authentication)
    bad_passwords = ["password", "passw0rd", "12345678", "1234abcd", "aaaaaaaa", "catsdogs"].each do |password|
      auth.password = password
      expect(auth).to_not be_valid, "password #{password} should not be valid"
      expect(auth.errors.messages[:password]).to eq [WEAK_PASSWORD_ERROR]
    end
  end

  it "cannot be the example password" do
    auth = build(:email_authentication, password: "logic finite eager ratio")
    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to eq ["cannot match the example password"]
  end

  it "should allow strong passwords" do
    auth = build(:email_authentication)
    good_passwords = ["three word passphrase", "speaker imac coverage flower", "@zadlfj4809574zk.vd", "long-pass-phrase-verklempt-basketball"].each do |password|
      auth.password = password
      expect(auth).to be_valid, "password #{password.inspect} should not be valid"
    end
  end

  it "should allow email to be updated even if the EmailAuthentication has a weak password" do
    auth = build(:email_authentication, password: "1234567890")
    auth.save(validate: false)
    auth = EmailAuthentication.find(auth.id)
    auth.email = "newemail@example.com"
    expect(auth).to be_valid
    auth.save!
    # make sure a weak password change is prevented
    auth.password = "stillweak"
    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to eq [WEAK_PASSWORD_ERROR]
  end
end
