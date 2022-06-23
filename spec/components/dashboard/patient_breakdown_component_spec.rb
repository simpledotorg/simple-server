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

    patient_breakdown_component = described_class.new(region: district, data: district_data, period: Period.current)

    render_inline(patient_breakdown_component)

    expect(page).to have_text("Total assigned patients")
    expect(page.find("#total-assigned-excluding-dead-patients").text.to_i).to eq(5)
  end
end
