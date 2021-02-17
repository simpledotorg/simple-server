require "rails_helper"

RSpec.describe EmailAuthentication, type: :model do

  describe "Associations" do
    it { should have_one(:user_authentication) }
    it { should have_one(:user).through(:user_authentication) }
  end

  it "requires a non blank password" do
    auth = build(:email_authentication, password: nil)

    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to include "can't be blank"
  end

  it "requires a password to be at least ten characters" do
    auth = build(:email_authentication, password: "a" * 9)

    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to include "must be at least 10 characters"
  end

  it "requires a password to have at least one number" do
    auth = build(:email_authentication, password: "A" * 10)

    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to include "must contain at least one lower case letter"
  end

  it "requires a password to have at least one lower case letter" do
    auth = build(:email_authentication, password: "a" * 10)

    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to include "must contain at least one upper case letter"
  end

  it "requires a password to have at least one upper case letter" do
    auth = build(:email_authentication, password: "NoNumbers!")

    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to include "must contain at least one number"
  end

  it "accepts valid passwords" do
    auth = build(:email_authentication, password: "V4lid8me!!!")
    expect(auth).to be_valid
  end

  it "allows email to be updated even if the EmailAuthentication has a weak password" do
    auth = build(:email_authentication, password: "1234567890")
    auth.save(validate: false)
    auth = EmailAuthentication.find(auth.id)
    auth.email = "newemail@example.com"
    expect(auth).to be_valid
    auth.save!
    # make sure a weak password change is prevented
    auth.password = "passw0rd"
    expect(auth).to_not be_valid
    expect(auth.errors.messages[:password]).to eq [weak_password_error]
  end
end
