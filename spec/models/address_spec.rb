require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:device_created_at)}
    it { should validate_presence_of(:device_updated_at)}
  end
end
