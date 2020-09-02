require "rails_helper"

RSpec.describe OrganizationDistrict, type: :model do
  describe "#cohort_analytics" do
    it "considers only registered hypertensive patients" do
      organization = create(:organization)
      facility_group = create(:facility_group, organization: organization)
      facility = create(:facility, facility_group: facility_group, district: "Bathinda")
      non_htn_patients_facility = create(:facility, facility_group: facility_group, district: "Bathinda")

      org_district = OrganizationDistrict.new("Bathinda", organization)

      Timecop.freeze("June 15th 2020") do
        _non_htn_patients = create_list(:patient, 2, :without_hypertension, registration_facility: non_htn_patients_facility, recorded_at: 4.months.ago)
        _htn_patients = create_list(:patient, 2, registration_facility: facility, recorded_at: 4.months.ago)
        controlled_htn_patients = create_list(:patient, 2, registration_facility: facility, recorded_at: 4.months.ago)
        controlled_htn_patients.each { |patient|
          create(:blood_pressure, :under_control, patient: patient, facility: facility, recorded_at: 3.months.ago)
        }

        result = org_district.cohort_analytics(:month, 3)
        march_key = [Date.parse("February 1st 2020"), Date.parse("March 1st 2020")]
        march_data = result[march_key]
        # ensure we don't have non HTN patients
        expect(march_data["registered"].key?(non_htn_patients_facility.id)).to be false
        # verify the other results
        expect(march_data["registered"]).to eq({facility.id => 4, "total" => 4})
        expect(march_data["followed_up"]).to eq({facility.id => 2, "total" => 2})
        expect(march_data["controlled"]).to eq({facility.id => 2, "total" => 2})
        expect(march_data["uncontrolled"]).to eq({facility.id => 0, "total" => 0})
      end
    end
  end
end
