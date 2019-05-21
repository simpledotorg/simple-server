require 'rails_helper'

RSpec.describe CallLog, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:caller_phone_number) }
    it { should validate_presence_of(:callee_phone_number) }
  end
end
