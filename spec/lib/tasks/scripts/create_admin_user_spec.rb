# frozen_string_literal: true

require "rails_helper"
require "tasks/scripts/create_admin_user"

RSpec.describe CreateAdminUser do
  describe "#create_owner" do
    let!(:name) { Faker::Name.name }
    let!(:email) { Faker::Internet.email }
    let!(:password) { generate(:strong_password) }

    it "should create a new user with owner permissions" do
      user = CreateAdminUser.create_owner(name, email, password)

      expect(user.access_level).to eq("power_user")
      expect(EmailAuthentication.find_by_email(email)).to be_present
    end
  end
end
