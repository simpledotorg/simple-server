require 'rails_helper'
require 'tasks/scripts/create_admin_user'

RSpec.describe CreateAdminUser do
  describe '#create_owner' do
    let!(:name) { Faker::Name.name }
    let!(:email) { Faker::Internet.email }
    let!(:password) { generate(:strong_password) }

    it 'should create a new user with owner permissions' do
      user = CreateAdminUser.create_owner(name, email, password)
      permissions = Permissions::ACCESS_LEVELS.find { |level| level[:name] == :owner }[:default_permissions]

      permissions.each do |permission|
        expect(user.has_permission?(permission)).to be true
      end
    end
  end
end
