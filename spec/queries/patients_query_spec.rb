require 'rails_helper'

RSpec.describe PatientsQuery, type: :query do
  let!(:this_facility) { FactoryBot.create(:facility) }
  let!(:other_facility) { FactoryBot.create(:facility) }
  let!(:patient_in_this_facility) { FactoryBot.create(:patient, registration_facility: this_facility) }
  let!(:patient_in_other_facility) { FactoryBot.create(:patient, registration_facility: other_facility) }

  it 'should return only patients registered in this_facility' do
    patients_in_this_facility = PatientsQuery.new.registered_at(this_facility.id)
    expect(patients_in_this_facility.count).to eq(1)
    expect(patients_in_this_facility.first).to eq(patient_in_this_facility)
  end

  it 'should return only patients registered in other_facility' do
    patients_in_this_facility = PatientsQuery.new.registered_at(other_facility.id)
    expect(patients_in_this_facility.count).to eq(1)
    expect(patients_in_this_facility.first).to eq(patient_in_other_facility)
  end
end