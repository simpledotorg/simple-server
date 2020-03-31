require 'rails_helper'

RSpec.describe LatestBloodPressuresPerPatient, type: :model do
  describe 'Associations' do
    it { should belong_to(:bp_facility) }
    it { should belong_to(:registration_facility) }
  end
end
