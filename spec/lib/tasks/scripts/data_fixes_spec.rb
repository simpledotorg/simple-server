# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.describe "data_fixes:move_user_data_from_source_to_destination_facility" do
  include RakeTestHelper
  let!(:registration_facility) { create(:facility) }
  let!(:other_facility) { create(:facility) }
  let!(:user) { create(:user, registration_facility: registration_facility) }
  let!(:wrong_facility_patients) { create_list(:patient, 3, registration_facility: other_facility, registration_user: user) }
  let!(:patient) { create(:patient, registration_facility: registration_facility, registration_user: user) }
  let!(:blood_pressures) { create_list(:blood_pressure, 2, patient: wrong_facility_patients.sample, user: user, facility: registration_facility) }
  let!(:wrong_facility_blood_pressures) { create_list(:blood_pressure, 3, patient: wrong_facility_patients.sample, user: user, facility: other_facility) }
  let!(:blood_sugars) { create_list(:blood_sugar, 2, patient: wrong_facility_patients.sample, user: user, facility: registration_facility) }
  let!(:wrong_facility_blood_sugars) { create_list(:blood_sugar, 3, patient: wrong_facility_patients.sample, user: user, facility: other_facility) }
  let!(:encounters) do
    (blood_pressures + blood_sugars + wrong_facility_blood_pressures + wrong_facility_blood_sugars).each do |record|
      create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility)
    end
  end
  let!(:appointments) { create_list(:appointment, 2, patient: wrong_facility_patients.sample, user: user, facility: registration_facility, creation_facility: other_facility) }
  let!(:wrong_facility_appointments) { create_list(:appointment, 3, patient: wrong_facility_patients.sample, user: user, facility: other_facility, creation_facility: other_facility) }
  let!(:prescription_drugs) { create_list(:prescription_drug, 2, patient: wrong_facility_patients.sample, user: user, facility: registration_facility) }
  let!(:wrong_facility_prescription_drugs) { create_list(:prescription_drug, 3, patient: wrong_facility_patients.sample, user: user, facility: other_facility) }
  let!(:task) { "data_fixes:move_user_data_from_source_to_destination_facility[#{user.id},#{other_facility.id},#{registration_facility.id}]" }

  it "moves the correct number of patients" do
    expect { invoke_task(task) }.to change { registration_facility.registered_patients.count }.by(wrong_facility_patients.count)
    expect(registration_facility.registered_patient_ids).to include(*wrong_facility_patients.pluck(:id))
  end

  it "moves the correct number of BPs" do
    expect { invoke_task(task) }.to change { registration_facility.blood_pressures.count }.by(wrong_facility_blood_pressures.count)
    expect(registration_facility.blood_pressure_ids).to include(*wrong_facility_blood_pressures.pluck(:id))
  end

  it "moves the correct number of blood sugars" do
    expect { invoke_task(task) }.to change { registration_facility.blood_sugars.count }.by(wrong_facility_blood_sugars.count)
    expect(registration_facility.blood_sugar_ids).to include(*wrong_facility_blood_sugars.pluck(:id))
  end

  it "moves the correct number of appointments" do
    expect { invoke_task(task) }.to change { registration_facility.appointments.count }.by(wrong_facility_appointments.count)
    expect(registration_facility.appointment_ids).to include(*wrong_facility_appointments.pluck(:id))
  end

  it "moves the correct number of prescription drugs" do
    expect { invoke_task(task) }.to change { registration_facility.prescription_drugs.count }.by(wrong_facility_prescription_drugs.count)
    expect(registration_facility.prescription_drug_ids).to include(*wrong_facility_prescription_drugs.pluck(:id))
  end
end
