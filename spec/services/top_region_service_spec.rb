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
      darrang_patients = create_list(:patient, 2, recorded_at: Time.current, registration_facility: darrang_facilities.first, registration_user: user)
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

    service = TopRegionService.new([organization], Period.month(june_1))
    result = service.call
    expect(result[:control_rate][:region]).to eq(koriya)
    expect(result[:control_rate][:value]).to eq(100.0)
  end

  it "gets top facility benchmarks" do
    darrang = FactoryBot.create(:facility_group, name: "Darrang", organization: organization)
    darrang_facility_1 = FactoryBot.create(:facility, name: "darrang-1", facility_group: darrang)
    darrang_facility_2 = FactoryBot.create(:facility, name: "darrang-2", facility_group: darrang)
    kadapa = FactoryBot.create(:facility_group, name: "Kadapa", organization: organization)
    kadapa_facility = FactoryBot.create(:facility, name: "kadapa-facility", facility_group: kadapa)
    other_org_district = FactoryBot.create(:facility_group, name: "other-org-district", organization: create(:organization))
    other_org_facility = FactoryBot.create(:facility, name: "other-org-facility", facility_group: other_org_district)

    Timecop.freeze("April 15th 2020") do
      # darrang_facility_1 control rate is 75% control
      top_facility_patients = create_list(:patient, 4, recorded_at: 1.month.ago, registration_facility: darrang_facility_1, registration_user: user)
      top_facility_patients.each_with_index do |patient, num|
        create(:blood_pressure, :hypertensive, facility: darrang_facility_1, patient: patient, recorded_at: 3.days.ago)
        create(:blood_pressure, :under_control, facility: darrang_facility_1, patient: patient, recorded_at: 2.days.ago)
        if num == 0
          create(:blood_pressure, :hypertensive, facility: darrang_facility_1, patient: patient, recorded_at: Time.current)
        end
      end
      # kadapa facility control rate is 33%
      kadapa_patients = create_list(:patient, 3, recorded_at: 1.month.ago, registration_facility: kadapa_facility, registration_user: user)
      kadapa_patients.each_with_index do |patient, num|
        create(:blood_pressure, :hypertensive, facility: kadapa_facility, patient: patient, recorded_at: 1.day.ago)
        if num == 0
          create(:blood_pressure, :under_control, facility: kadapa_facility, patient: patient, recorded_at: Time.current)
        end
      end
      # Kadapa facility has 6 registrations
      _other_kadapa_patients = create_list(:patient, 3, recorded_at: 1.month.ago, registration_facility: kadapa_facility, registration_user: user)

      # darrang_facility_2 control rate is 0%
      other_darrang_patients = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: darrang_facility_2, registration_user: user)
      other_darrang_patients.each do |patient|
        create(:blood_pressure, :hypertensive, facility: darrang_facility_2, patient: patient, recorded_at: Time.current)
      end
      # other org control rate is 100%, but in a different org that is not included in benchmark
      other_org_patients = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: other_org_facility, registration_user: user)
      other_org_patients.each do |patient|
        create(:blood_pressure, :under_control, facility: other_org_facility, patient: patient, recorded_at: Time.current)
      end
    end

    refresh_views

    service = TopRegionService.new([organization], Period.month(june_1), scope: :facility)
    result = service.call
    expect(result[:control_rate][:region]).to eq(darrang_facility_1)
    expect(result[:control_rate][:value]).to eq(75.0)
    expect(result[:cumulative_registrations][:region]).to eq(kadapa_facility)
    expect(result[:cumulative_registrations][:value]).to eq(6)
  end
end
