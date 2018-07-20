require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:email)}
    it { should validate_presence_of(:password)}
    it { should validate_presence_of(:role) }

    it { should define_enum_for(:role).with([:owner, :supervisor]) }
  end
end
