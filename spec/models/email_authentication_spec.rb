require "rails_helper"

RSpec.describe EmailAuthentication, type: :model do
  WEAK_PASSWORD_ERROR = "Please choose a stronger password with at least 8 characters. Try a mix of letters, numbers, and symbols."

  describe "Associations" do
    it { should have_one(:user_authentication) }
    it { should have_one(:user).through(:user_authentication) }
  end

  it "requires a non blank password" do
    auth = build(:email_authentication, password: "")
    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to eq [WEAK_PASSWORD_ERROR]
  end

  it "requires a strong password" do
    auth = build(:email_authentication)
    bad_passwords = ["password", "passw0rd", "12345678", "1234abcd", "aaaaaaaa", "catsdogs"].each do |password|
      auth.password = password
      expect(auth).to_not be_valid, "password #{password} should not be valid"
      expect(auth.errors.messages[:password]).to eq [WEAK_PASSWORD_ERROR]
    end
  end

  it "allows strong passwords" do
    auth = build(:email_authentication)
    good_passwords = ["three word passphrase", "speaker imac coverage flower", "@zadlfj4809574zk.vd", "long-pass-phrase-verklempt-basketball"].each do |password|
      auth.password = password
      expect(auth).to be_valid, "password #{password.inspect} should not be valid"
    end
  end

  it "allows email to be updated even if the EmailAuthentication has a weak password" do
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
