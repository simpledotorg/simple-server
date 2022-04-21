require "rails_helper"

describe Reports::PatientBloodSugar, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  around do |example|
    with_reporting_time_zone { example.run }
  end

  it "has the latest blood sugar details for every month a patient has their blood sugar measured" do
    patient = create(:patient)
    blood_sugar_1 = create(:blood_sugar, patient: patient, recorded_at: 6.months.ago)
    blood_sugar_2 = create(:blood_sugar, patient: patient, recorded_at: 2.months.ago)
    blood_sugar_3 = create(:blood_sugar, patient: patient, recorded_at: 1.months.ago)
    blood_sugar_4 = create(:blood_sugar, patient: patient)

    refresh_views
    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :blood_sugar_id,
      :patient_id
    )
    expect(results).to include(
      [june_2021[:six_months_ago].to_date, blood_sugar_1.id, patient.id],
      [june_2021[:two_months_ago].to_date, blood_sugar_2.id, patient.id],
      [june_2021[:one_month_ago].to_date, blood_sugar_3.id, patient.id],
      [june_2021[:now].to_date, blood_sugar_4.id, patient.id]
    )
  end

  it "does not contain months for a patient until their first blood sugar measurement is taken" do
    patient = create(:patient, recorded_at: 3.months.ago)
    create(:blood_sugar, patient: patient, recorded_at: 1.month.ago)

    refresh_views
    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :patient_id
    )

    expect(results).to include([june_2021[:one_month_ago].to_date, patient.id])
    expect(results).not_to include([june_2021[:two_months_ago].to_date, patient.id])
    expect(results).not_to include([june_2021[:three_months_ago].to_date, patient.id])
  end

  it "has the latest blood sugar details from a previous month if the patient doesn't have their blood sugar measured in that month" do
    patient = create(:patient)
    blood_sugar_1 = create(:blood_sugar, patient: patient, recorded_at: 3.months.ago)
    blood_sugar_2 = create(:blood_sugar, patient: patient, recorded_at: 2.months.ago)
    blood_sugar_3 = create(:blood_sugar, patient: patient)

    refresh_views
    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :blood_sugar_id,
      :patient_id
    )
    expect(results).to include(
      [june_2021[:three_months_ago].to_date, blood_sugar_1.id, patient.id],
      [june_2021[:two_months_ago].to_date, blood_sugar_2.id, patient.id],
      [june_2021[:one_month_ago].to_date, blood_sugar_2.id, patient.id],
      [june_2021[:now].to_date, blood_sugar_3.id, patient.id]
    )
  end

  it "has the details of the latest blood sugar measurement for a month, if the month has more than one measurement" do
    patient = create(:patient)
    blood_sugar_1 = create(:blood_sugar, patient: patient, recorded_at: june_2021[:now] + 10.days)
    blood_sugar_2 = create(:blood_sugar, patient: patient, recorded_at: june_2021[:now] + 15.days)

    refresh_views

    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :blood_sugar_recorded_at,
      :blood_sugar_id,
      :patient_id
    )

    expect(results).to include(
      [june_2021[:now].to_date, june_2021[:now] + 15.days, blood_sugar_2.id, patient.id]
    )

    expect(results).not_to include(
      [june_2021[:now].to_date, june_2021[:now] + 10.days, blood_sugar_1.id, patient.id]
    )
  end

  it "contains number of months and quarters since patient registration" do
    patient_1 = create(:patient, recorded_at: june_2021[:six_months_ago])
    patient_2 = create(:patient, recorded_at: june_2021[:three_months_ago])

    create(:blood_sugar, patient: patient_1, recorded_at: 3.months.ago)
    create(:blood_sugar, patient: patient_1)
    create(:blood_sugar, patient: patient_2, recorded_at: 3.months.ago)
    create(:blood_sugar, patient: patient_2)

    refresh_views

    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :patient_id,
      :months_since_registration,
      :quarters_since_registration
    )

    expect(results).to include(
      # Patient 1
      [june_2021[:three_months_ago].to_date, patient_1.id, 3, 1],
      [june_2021[:two_months_ago].to_date, patient_1.id, 4, 2],
      [june_2021[:one_month_ago].to_date, patient_1.id, 5, 2],
      [june_2021[:now].to_date, patient_1.id, 6, 2],
      # Patient 2
      [june_2021[:three_months_ago].to_date, patient_2.id, 0, 0],
      [june_2021[:two_months_ago].to_date, patient_2.id, 1, 1],
      [june_2021[:one_month_ago].to_date, patient_2.id, 2, 1],
      [june_2021[:now].to_date, patient_2.id, 3, 1]
    )
  end

  it "contains number of months and quarters since blood sugarg measurement" do
    patient = create(:patient, recorded_at: june_2021[:six_months_ago])
    create(:blood_sugar, patient: patient, recorded_at: 5.months.ago)
    create(:blood_sugar, patient: patient, recorded_at: 1.months.ago)
    create(:blood_sugar, patient: patient)
    refresh_views

    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :patient_id,
      :months_since_bs,
      :quarters_since_bs
    )

    expect(results).to include(
      [june_2021[:five_months_ago].to_date, patient.id, 0, 0],
      [june_2021[:four_months_ago].to_date, patient.id, 1, 0],
      [june_2021[:three_months_ago].to_date, patient.id, 2, 0],
      [june_2021[:two_months_ago].to_date, patient.id, 3, 1],
      [june_2021[:one_month_ago].to_date, patient.id, 0, 0],
      [june_2021[:now].to_date, patient.id, 0, 0]
    )
  end

  it "contains the risk-state for the blood sugar measurement" do
    patients = create_list(:patient, 4)
    random_bs_below_200 = create(:blood_sugar, patient: patients.first, blood_sugar_type: :random, blood_sugar_value: 150, recorded_at: 5.months.ago)
    random_bs_200_to_300 = create(:blood_sugar, patient: patients.first, blood_sugar_type: :random, blood_sugar_value: 250, recorded_at: 4.months.ago)
    random_bs_over_300 = create(:blood_sugar, patient: patients.first, blood_sugar_type: :random, blood_sugar_value: 350, recorded_at: 3.months.ago)
    random_bs_200 = create(:blood_sugar, patient: patients.first, blood_sugar_type: :random, blood_sugar_value: 200, recorded_at: 2.months.ago)
    random_bs_300 = create(:blood_sugar, patient: patients.first, blood_sugar_type: :random, blood_sugar_value: 300, recorded_at: 1.months.ago)

    post_prandial_bs_below_200 = create(:blood_sugar, patient: patients.second, blood_sugar_type: :post_prandial, blood_sugar_value: 150, recorded_at: 5.months.ago)
    post_prandial_bs_200_to_300 = create(:blood_sugar, patient: patients.second, blood_sugar_type: :post_prandial, blood_sugar_value: 250, recorded_at: 4.months.ago)
    post_prandial_bs_over_300 = create(:blood_sugar, patient: patients.second, blood_sugar_type: :post_prandial, blood_sugar_value: 350, recorded_at: 3.months.ago)
    post_prandial_bs_200 = create(:blood_sugar, patient: patients.second, blood_sugar_type: :post_prandial, blood_sugar_value: 200, recorded_at: 2.months.ago)
    post_prandial_bs_300 = create(:blood_sugar, patient: patients.second, blood_sugar_type: :post_prandial, blood_sugar_value: 300, recorded_at: 1.months.ago)

    fasting_bs_below_200 = create(:blood_sugar, patient: patients.third, blood_sugar_type: :fasting, blood_sugar_value: 100, recorded_at: 5.months.ago)
    fasting_bs_200_to_300 = create(:blood_sugar, patient: patients.third, blood_sugar_type: :fasting, blood_sugar_value: 150, recorded_at: 4.months.ago)
    fasting_bs_over_300 = create(:blood_sugar, patient: patients.third, blood_sugar_type: :fasting, blood_sugar_value: 250, recorded_at: 3.months.ago)
    fasting_bs_200 = create(:blood_sugar, patient: patients.third, blood_sugar_type: :fasting, blood_sugar_value: 126, recorded_at: 2.months.ago)
    fasting_bs_300 = create(:blood_sugar, patient: patients.third, blood_sugar_type: :fasting, blood_sugar_value: 200, recorded_at: 1.months.ago)

    hba1c_bs_below_200 = create(:blood_sugar, patient: patients.fourth, blood_sugar_type: :hba1c, blood_sugar_value: 6.5, recorded_at: 5.months.ago)
    hba1c_bs_200_to_300 = create(:blood_sugar, patient: patients.fourth, blood_sugar_type: :hba1c, blood_sugar_value: 7.5, recorded_at: 4.months.ago)
    hba1c_bs_over_300 = create(:blood_sugar, patient: patients.fourth, blood_sugar_type: :hba1c, blood_sugar_value: 9.5, recorded_at: 3.months.ago)
    hba1c_bs_200 = create(:blood_sugar, patient: patients.fourth, blood_sugar_type: :hba1c, blood_sugar_value: 7.0, recorded_at: 2.months.ago)
    hba1c_bs_300 = create(:blood_sugar, patient: patients.fourth, blood_sugar_type: :hba1c, blood_sugar_value: 9.0, recorded_at: 1.months.ago)

    refresh_views

    results = Reports::PatientBloodSugar.all.pluck(
      :month_date,
      :patient_id,
      :blood_sugar_id,
      :blood_sugar_risk_state
    )

    risk_states = Reports::PatientBloodSugar.blood_sugar_risk_states

    expect(results).to include(
      # Random blood sugars
      [june_2021[:five_months_ago].to_date, patients.first.id, random_bs_below_200.id, risk_states[:bs_below_200]],
      [june_2021[:four_months_ago].to_date, patients.first.id, random_bs_200_to_300.id, risk_states[:bs_200_to_300]],
      [june_2021[:three_months_ago].to_date, patients.first.id, random_bs_over_300.id, risk_states[:bs_over_300]],
      [june_2021[:two_months_ago].to_date, patients.first.id, random_bs_200.id, risk_states[:bs_200_to_300]],
      [june_2021[:one_month_ago].to_date, patients.first.id, random_bs_300.id, risk_states[:bs_over_300]],
      # Post prandial blood sugars
      [june_2021[:five_months_ago].to_date, patients.second.id, post_prandial_bs_below_200.id, risk_states[:bs_below_200]],
      [june_2021[:four_months_ago].to_date, patients.second.id, post_prandial_bs_200_to_300.id, risk_states[:bs_200_to_300]],
      [june_2021[:three_months_ago].to_date, patients.second.id, post_prandial_bs_over_300.id, risk_states[:bs_over_300]],
      [june_2021[:two_months_ago].to_date, patients.second.id, post_prandial_bs_200.id, risk_states[:bs_200_to_300]],
      [june_2021[:one_month_ago].to_date, patients.second.id, post_prandial_bs_300.id, risk_states[:bs_over_300]],
      # Fasting blood sugars
      [june_2021[:five_months_ago].to_date, patients.third.id, fasting_bs_below_200.id, risk_states[:bs_below_200]],
      [june_2021[:four_months_ago].to_date, patients.third.id, fasting_bs_200_to_300.id, risk_states[:bs_200_to_300]],
      [june_2021[:three_months_ago].to_date, patients.third.id, fasting_bs_over_300.id, risk_states[:bs_over_300]],
      [june_2021[:two_months_ago].to_date, patients.third.id, fasting_bs_200.id, risk_states[:bs_200_to_300]],
      [june_2021[:one_month_ago].to_date, patients.third.id, fasting_bs_300.id, risk_states[:bs_over_300]],
      # Hba1c blood sugars
      [june_2021[:five_months_ago].to_date, patients.fourth.id, hba1c_bs_below_200.id, risk_states[:bs_below_200]],
      [june_2021[:four_months_ago].to_date, patients.fourth.id, hba1c_bs_200_to_300.id, risk_states[:bs_200_to_300]],
      [june_2021[:three_months_ago].to_date, patients.fourth.id, hba1c_bs_over_300.id, risk_states[:bs_over_300]],
      [june_2021[:two_months_ago].to_date, patients.fourth.id, hba1c_bs_200.id, risk_states[:bs_200_to_300]],
      [june_2021[:one_month_ago].to_date, patients.fourth.id, hba1c_bs_300.id, risk_states[:bs_over_300]]
    )
  end
end
