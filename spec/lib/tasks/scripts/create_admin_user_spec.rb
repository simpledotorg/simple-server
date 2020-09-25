require "rails_helper"
require "tasks/scripts/create_admin_user"

RSpec.describe CreateAdminUser do
  describe "#create_owner" do
    let!(:name) { Faker::Name.name }
    let!(:email) { Faker::Internet.email }
    let!(:password) { generate(:strong_password) }

    it "should create a new user with power_user access" do
      user = CreateAdminUser.create_owner(name, email, password)

      expect(user.power_user?).to be true
    end
  end
end
