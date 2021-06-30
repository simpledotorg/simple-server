require "rails_helper"

RSpec.describe ControlRateQueryV2 do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:query) { ControlRateQueryV2.new }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_1_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

  def refresh_views
    logger.info "about to refresh mat views..."
    RefreshMaterializedViews.new.refresh_v2
  end

  it "works" do
    facility = FactoryBot.create(:facility, facility_group: facility_group_1)
    patients = [
      create(:patient, recorded_at: jan_2019, assigned_facility: facility, registration_user: user),
      create(:patient, status: :dead, recorded_at: jan_2019, assigned_facility: facility, registration_user: user)
    ]
    controlled = patients.first

    Timecop.freeze(june_1_2020) do
      patients.each do |patient|
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    Timecop.freeze(july_1_2020) do
      refresh_views
      with_reporting_time_zone do
        expect(query.controlled(facility.region).to_a.first.patient_id).to eq(controlled.id)
        expect(query.controlled_counts(facility.region)).to eq({
          Period.month("May 2020") => 1,
          Period.month("June 2020") => 1,
          Period.month("July 2020") => 1
        })
      end
    end
  end
end
