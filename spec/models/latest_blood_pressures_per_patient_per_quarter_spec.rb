require 'rails_helper'

RSpec.describe LatestBloodPressuresPerPatientPerQuarter, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end
end
