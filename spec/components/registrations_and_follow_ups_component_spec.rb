require "rails_helper"

RSpec.describe RegistrationsAndFollowUpsComponent, type: :component do
  let(:cvho) { create(:admin, :manager, :with_access, resource: common_org, organization: common_org) }
  let(:jan_2020) { Time.zone.parse("January 1 2020") }

  it "can be created" do
    facility_group = create(:facility_group, organization: common_org)
    facility = create(:facility, name: "CHC Barnagar", facility_group: facility_group)

    patient = create(:patient, registration_facility: facility, recorded_at: jan_2020.advance(months: -4))
    create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: facility)
    create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: facility)

    repo = Reports::Repository.new(facility, periods: jan_2020.to_period)
    described_class.new(facility, current_admin: cvho, repository: repo, current_period: jan_2020.to_period)
  end
end
