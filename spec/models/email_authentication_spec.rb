require 'rails_helper'

RSpec.describe EmailAuthentication, type: :model do
  describe 'Associations' do
    it { should have_one(:master_user_authentication) }
    it { should have_one(:master_user).through(:master_user_authentication) }
  end
end
