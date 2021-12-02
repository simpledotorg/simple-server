require "rails_helper"

RSpec.describe Reports::PatientFollowUp, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should belong_to(:user) }
  end

  let(:user) { create(:user) }

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  # without the distinct on 
  #   -> facility 7519
  #   -> all 1484532
  # with distinct on 
  #   -> first facility 7463
  #   -> all 1459613
  it "contains records for patient BPs" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up.month_string).to eq(june_2021[:month_string])
  end

  it "contains records for appointments" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    create(:appointment, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up.month_string).to eq(june_2021[:month_string])
  end

  it "contains separate records for distinct months" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:over_3_months_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:under_3_months_ago])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient, user: user, facility: facility)
    expect(follow_ups.map(&:month_string).sort).to eq(["2021-03", "2021-04"])
  end

  it "contains separate records for distinct users in the same month" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_user = create(:user)
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: patient, user: another_user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient, month_string: june_2021[:month_string], facility: facility)
    expect(follow_ups.map(&:user)).to contain_exactly(user, another_user)
  end

  it "contains separate records for distinct facilities" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)
    another_facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: patient, user: user, facility: another_facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient, month_string: june_2021[:month_string], user: user)
    expect(follow_ups.map(&:facility)).to contain_exactly(facility, another_facility)
  end

  it "contains separate records for distinct patients" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: another_patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(month_string: june_2021[:month_string], facility: facility, user: user)
    expect(follow_ups.map(&:patient)).to contain_exactly(patient, another_patient)
  end

  it "does not count activity in the registration month" do
    patient = create(:patient, recorded_at: june_2021[:beginning_of_month])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])

    RefreshReportingViews.call

    expect(described_class.count).to eq(0)
  end

  it "does not count more than one visit per month for the same patient, facility, and user" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:beginning_of_month])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:blood_sugar, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:appointment, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:prescription_drug, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility, month_string: june_2021[:month_string])
    expect(follow_up).to be_present
  end

  it "identifies months in the reporting timezone" do
    patient = create(:patient, recorded_at: june_2021[:over_12_months_ago])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:under_12_months_ago])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
  end
end
