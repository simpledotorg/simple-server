require "rails_helper"

RSpec.describe TopRegionService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) do
    create(:admin, :supervisor, organization: organization).tap do |user|
      user.user_permissions << build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
    end
  end
  let(:june_1) { Time.parse("June 1st, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "gets top district benchmarks" do
    darrang = FactoryBot.create(:facility_group, name: "Darrang", organization: organization)
    darrang_facilities = FactoryBot.create_list(:facility, 2, facility_group: darrang)
    kadapa = FactoryBot.create(:facility_group, name: "Kadapa", organization: organization)
    _kadapa_facilities = FactoryBot.create_list(:facility, 2, facility_group: kadapa)
    koriya = FactoryBot.create(:facility_group, name: "Koriya", organization: organization)
    koriya_facilities = FactoryBot.create_list(:facility, 2, facility_group: koriya)

    Timecop.freeze("April 1st 2020") do
      darrang_patients = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: darrang_facilities.first, registration_user: user)
      darrang_patients.each do |patient|
        create(:blood_pressure, :hypertensive, facility: darrang_facilities.first, patient: patient, recorded_at: Time.current)
      end
    end
    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 4, recorded_at: 1.month.ago, registration_facility: koriya_facilities.first, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: koriya_facilities.first, patient: patient, recorded_at: Time.current)
      end
    end

    refresh_views

    service = TopRegionService.new([organization], june_1.end_of_month)
    result = service.call
    expect(result[:district]).to eq(koriya)
    expect(result[:controlled_percentage]).to eq(100.0)
  end
end
