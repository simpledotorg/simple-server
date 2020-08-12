require "rails_helper"

RSpec.describe OrganizationDistrict, type: :model do
  describe "#cohort_analytics" do
    it "considers only assigned hypertensive patients" do
      organization = create(:organization)
      facility_group = create(:facility_group, organization: organization)
      registration_facility_group = create(:facility_group, organization: organization)
      facility1 = create(:facility, facility_group: facility_group, district: "Bathinda")
      facility2 = create(:facility, facility_group: facility_group, district: "Bathinda")
      registration_facility = create(:facility, facility_group: registration_facility_group, district: "Mansa")

      org_district = OrganizationDistrict.new("Bathinda", organization)

      _non_htn_patients = create_list(:patient, 2, :without_hypertension, assigned_facility: facility1, registration_facility: registration_facility)
      htn_patients = create_list(:patient, 2, assigned_facility: facility2, registration_facility: registration_facility)

      expect(CohortAnalyticsQuery).to receive(:new).with(match_array(htn_patients)).and_call_original

      org_district.cohort_analytics(:month, 3)
    end
  end
end
