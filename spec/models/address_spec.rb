require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'Validations' do
    it_behaves_like 'application record'
  end
end
