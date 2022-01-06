# frozen_string_literal: true

require "rails_helper"

RSpec.describe OverdueCallsQuery do
  it "returns counts of calls per period" do
    facility = create(:facility)
    user_1 = create(:user, registration_facility: facility)
    user_2 = create(:user, registration_facility: facility)
    Timecop.freeze("May 5th 2021") do
      appointment_1 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_1)
      appointment_2 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_2)
      create(:call_result, appointment: appointment_1, device_created_at: 4.months.ago, user: user_1)
      create(:call_result, appointment: appointment_2, device_created_at: 2.months.ago, user: user_2)
      expected = {
        Period.month("January 2021") => 1,
        Period.month("February 2021") => 0,
        Period.month("March 2021") => 1
      }

      RefreshReportingViews.new.refresh_v2
      expect(described_class.new.count(facility.region, :month)).to eq(expected)
    end
  end

  it "handles period boundaries correctly, taking into account time zones" do
    skip "needs investigation from @vkrm, this is currently broken"
    facility = create(:facility)
    end_of_jan = Time.zone.parse("January 31st 23:59:59 IST")
    beg_of_feb = Time.zone.parse("February 1st 00:00:00 IST")
    user_1 = create(:user, registration_facility: facility)
    user_2 = create(:user, registration_facility: facility)
    appointment_1 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_1)
    appointment_2 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_2)
    create(:call_result, appointment: appointment_1, device_created_at: end_of_jan, user: user_1)
    create(:call_result, appointment: appointment_2, device_created_at: beg_of_feb, user: user_2)

    RefreshReportingViews.new.refresh_v2
    with_reporting_time_zone do
      expected = {
        Period.month("January 2021") => 1,
        Period.month("February 2021") => 1
      }
      expect(described_class.new.count(facility.region, :month)).to eq(expected)
    end
  end

  it "can return counts of call results per period per user" do
    facility = create(:facility)
    user_1 = create(:user, registration_facility: facility)
    user_2 = create(:user, registration_facility: facility)
    appointment_1 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_1)
    appointment_2 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_2)
    appointment_3 = create(:appointment, facility: facility, device_created_at: 4.months.ago, user: user_2)

    Timecop.freeze("May 5th 2021") do
      create(:call_result, appointment: appointment_1, device_created_at: 4.months.ago, user: user_1)
      create(:call_result, appointment: appointment_2, device_created_at: 2.months.ago, user: user_2)
      create(:call_result, appointment: appointment_3, device_created_at: 2.months.ago, user: user_2)
      expected = {
        Period.month("January 2021") => {user_1.id => 1, user_2.id => 0},
        Period.month("February 2021") => {user_1.id => 0, user_2.id => 0},
        Period.month("March 2021") => {user_1.id => 0, user_2.id => 2}

      }

      RefreshReportingViews.new.refresh_v2
      expect(described_class.new.count(facility.region, :month, group_by: :user_id)).to eq(expected)
    end
  end
end
