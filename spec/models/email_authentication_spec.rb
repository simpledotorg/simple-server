require "rails_helper"

RSpec.describe EmailAuthentication, type: :model do

  describe "Associations" do
    it { should have_one(:user_authentication) }
    it { should have_one(:user).through(:user_authentication) }
  end

  describe "password" do
    it "can't be nil" do
      auth = build(:email_authentication, password: nil)

      expect(auth).to_not be_valid
      expect(auth.errors.messages[:password]).to include "can't be blank"
    end

    it "can't be blank" do
      auth = build(:email_authentication, password: "")

      expect(auth).to_not be_valid
      # expect(auth.errors.messages[:password]).to include "can't be blank"
    end

    it "requires at least ten characters" do
      auth = build(:email_authentication, password: "a" * 9)

      expect(auth).to_not be_valid
      # expect(auth.errors.messages[:password]).to include "must be at least 10 characters"
    end

    it "requires at least one number" do
      auth = build(:email_authentication, password: "A" * 10)

      expect(auth).to_not be_valid
      # expect(auth.errors.messages[:password]).to include "must contain at least one lower case letter"
    end

    it "requires at least one lower case letter" do
      auth = build(:email_authentication, password: "a" * 10)

      expect(auth).to_not be_valid
      # expect(auth.errors.messages[:password]).to include "must contain at least one upper case letter"
    end

    it "requires at least one upper case letter" do
      auth = build(:email_authentication, password: "NoNumbers!")

      expect(auth).to_not be_valid
      # expect(auth.errors.messages[:password]).to include "must contain at least one number"
    end

    it "is valid when it is at least ten characters and includes a number and lower and upper case letters" do
      auth = build(:email_authentication, password: "V4lid8me!!!")
      expect(auth).to be_valid
    end
  end

  it "is considered a valid EmailAuthentication even if the password in the database is invalid" do
    auth = build(:email_authentication, password: "1")
    auth.save(validate: false)
    auth = EmailAuthentication.find(auth.id)
    auth.touch
    expect(auth).to be_valid
  end

  it "allows email to be updated even if the EmailAuthentication has a weak password" do
    weak_password_error = "Password must be 10 characters long and contain a lower case letter, an upper case letter, and a number."
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
