require 'rails_helper'

RSpec.describe LatestBloodPressuresPerPatient, type: :model do
  describe 'Associations' do
    it { should belong_to(:facility) }
  end
end
