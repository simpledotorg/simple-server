require "rails_helper"

describe Dashboard::PatientBreakdownComponent, type: :component do
  it "Number of patients who are under care and lost to follow up should add up to total number of assigned patients" do
    region_hash = setup_district_with_facilities
    facility_1 = region_hash[:facility_1]
    facility_2 = region_hash[:facility_2]
    district = region_hash[:region]

    create_list(:patient, 3, :diabetes, :under_care, assigned_facility: facility_1, registration_facility: facility_1)
    create_list(:patient, 2, :diabetes, :lost_to_follow_up, assigned_facility: facility_2, registration_facility: facility_2)
    create_list(:patient, 1, :diabetes, :dead, assigned_facility: facility_1, registration_facility: facility_1)

    RefreshReportingViews.refresh_v2

    range = Range.new(Period.month(2.months.ago), Period.current)
    repo = Reports::Repository.new(district, periods: range)
    presenter = Reports::RepositoryPresenter.new(repo)
    district_data = presenter.call(district)
    _facility_1_data = presenter.call(facility_1)
    _facility_2_data = presenter.call(facility_2)
    period = Period.current

    patient_breakdown_component = described_class.new(
      region: district,
      data: {
        cumulative_assigned_patients: district_data.dig(:cumulative_assigned_diabetes_patients, period),
        cumulative_registrations: district_data.dig(:cumulative_diabetes_registrations, period),
        under_care_patients: district_data.dig(:diabetes_under_care, period),
        ltfu_patients: district_data.dig(:diabetes_ltfu_patients, period),
        dead_patients: district_data.dig(:diabetes_dead, period)
      },
      period: period,
      tooltips: {}
    )

    render_inline(patient_breakdown_component)

    cumulative_assigned_patients = page.find("#cumulative-assigned-patients").text.to_i
    cumulative_registrations = page.find("#cumulative-registrations").text.to_i
    under_care_patients = page.find("#under-care-patients").text.to_i
    ltfu_patients = page.find("#ltfu-patients").text.to_i
    dead_patients = page.find("#dead-patients").text.to_i

    expect(cumulative_assigned_patients).to eq(5)
    expect(under_care_patients).to eq(3)
    expect(ltfu_patients).to eq(2)
    expect(dead_patients).to eq(1)
    expect(cumulative_registrations).to eq(6)
    expect(cumulative_assigned_patients).to eq(under_care_patients + ltfu_patients)
    expect(under_care_patients + ltfu_patients).to eq(5)
  end
end
