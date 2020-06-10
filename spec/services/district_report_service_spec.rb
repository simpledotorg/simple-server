require "rails_helper"

describe DistrictReportService, type: :model do
  it "retrieves data for district" do
    facility_group = FactoryBot.create(:facility_group, name: "Darrang")
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group)
    Timecop.freeze("Jan 1, 2020") do
      p facilities.sample
      FactoryBot.create_list(:blood_pressure, 3, :hypertensive, facility: facilities.sample)
      FactoryBot.create_list(:blood_pressure, 3, :under_control, facility: facilities.sample)
    end

    june_1 = Time.parse("June 1, 2020")
    service = DistrictReportService.new(facilities: facilities, selected_date: june_1)
    result = service.call

    # @data = {
    #   controlled_patients: {},
    #   registrations: {},
    #   cumulative_registrations: 0,
    #   quarterly_registrations: []
    # }.with_indifferent_access
    expect(result[:controlled_patients].size).to eq(12)
    expect(result[:controlled_patients]["Jan 2020"]).to eq(3)
    p result[:controlled_patients]

  end
end