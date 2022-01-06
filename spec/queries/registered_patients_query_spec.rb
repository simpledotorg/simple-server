# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegisteredPatientsQuery do
  let(:user) { create(:user) }

  it "counts hypertensive registered patients by period" do
    facility = create(:facility)
    other_facility = create(:facility)
    user1 = create(:user)
    user2 = create(:user)
    Timecop.freeze("April 15th 2020") do
      create_list(:patient, 2, registration_facility: facility, registration_user: user1)
      create_list(:patient, 2, registration_facility: facility, registration_user: user1, recorded_at: "January 15 2020")
      create(:patient, :without_hypertension, registration_facility: facility)
      create_list(:patient, 1, registration_facility: other_facility, registration_user: user2)
    end
    result = described_class.new.count(facility, :month)
    expect(result[Period.month("December 1st 2020")]).to be_nil
    expect(result[Period.month("January 1st 2020")]).to eq(2)
    expect(result[Period.month("April 1st 2020")]).to eq(2)
  end

  it "includes dead patients" do
    facility = create(:facility)
    other_facility = create(:facility)
    create(:patient, registration_facility: facility, recorded_at: 3.months.ago, status: :dead, registration_user: user)
    create(:patient, registration_facility: other_facility, recorded_at: 2.months.ago, registration_user: user)
    result = described_class.new.count(facility, :month)
    expect(result).to eq({
      3.month.ago.to_period => 1
    })
  end

  it "can count by optional group_by arg" do
    facility = create(:facility)
    user1 = create(:user)
    user2 = create(:user)
    Timecop.freeze("April 15th 2020") do
      create_list(:patient, 2, registration_facility: facility, registration_user: user1)
      create_list(:patient, 2, registration_facility: facility, registration_user: user1, recorded_at: "January 15 2020")
      create_list(:patient, 3, registration_facility: facility, registration_user: user2)
      create(:patient, :without_hypertension, registration_facility: facility)
    end
    result = described_class.new.count(facility, :month, group_by: :registration_user_id)
    expected_for_jan = {
      user1.id => 2,
      user2.id => 0
    }
    expect(result[Period.month("January 1st 2020")]).to eq(expected_for_jan)
    expected_for_april = {
      user1.id => 2,
      user2.id => 3
    }
    expect(result[Period.month("April 1st 2020")]).to eq(expected_for_april)
  end
end
