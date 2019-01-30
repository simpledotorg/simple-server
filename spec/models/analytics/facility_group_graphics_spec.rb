require 'rails_helper'

RSpec.describe Analytics::FacilityGroupGraphics do
  let(:organization) { create :organization }
  let(:facility_group) { create :facility_group, organization: organization }
  let(:facility_1) { create :facility, facility_group: facility_group }
  let(:facility_2) { create :facility, facility_group: facility_group }

  before :each do
    create_list :patient, 10, registration_facility: facility_1
    create_list :patient, 10, registration_facility: facility_2
  end

  describe 'statistics required for graphics' do
    let(:facility_group_graphics) { Analytics::FacilityGroupGraphics.new(facility_group) }

    it 'has newly enrolled patients' do
      expect(facility_group_graphics.newly_enrolled_patients_count).to eq(20)
    end
  end
end
