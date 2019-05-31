require 'rails_helper'

RSpec.describe EmailAuthentication, type: :model do
  describe 'Associations' do
    it { should have_one(:user_authentication) }
    it { should have_one(:master_user).through(:user_authentication) }
  end
end
