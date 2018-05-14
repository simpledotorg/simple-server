require 'rails_helper'

def build_patient
  patient       = FactoryBot.build(:patient)
  address       = patient.address
  phone_numbers = patient.phone_numbers
  payload       = patient.attributes.merge(
    'address'       => address.attributes,
    'phone_numbers' => phone_numbers.map(&:attributes)
  ).except('address_id')
end

RSpec.describe Api::V1::PatientsController, type: :controller do
  describe 'POST sync' do
    it 'creates new patients' do
      patients = (1..10).map { build_patient }
      post(:sync_from_user, params: { patients: patients })
      expect(Patient.count).to eq 10
      expect(Address.count).to eq 10
      expect(PhoneNumber.count).to eq(patients.sum { |patient| patient['phone_numbers'].count })
      expect(response).to have_http_status(200)
    end

    it 'creates new patients without address' do
      post(:sync_from_user, params: { patients: [build_patient.except('address')] })
      expect(Patient.count).to eq 1
      expect(Address.count).to eq 0
      expect(response).to have_http_status(200)
    end

    it 'updates the existing patients' do
      existing_patients = FactoryBot.create_list(:patient, 10)
      updated_patients  = existing_patients.take(5).each do |patient|
        FactoryBot.attributes_for(
          :patient,
          id:         patient.id,
          updated_at: Time.now + 10.seconds)
      end

      post :sync_from_user, params: { patients: updated_patients.map(&:attributes) }
      db_patients = Patient.where(id: updated_patients.map(&:id))
      expect(db_patients.to_set).to eq(updated_patients.to_set)
    end

    it 'updates the existing patients and their addresses with nested attributes' do
      existing_patients = FactoryBot.create_list(:patient, 10)
      updated_patients  = existing_patients.take(5).map do |existing_patient|

        build_patient.deep_merge(
          'id'            => existing_patient.id,
          'phone_numbers' => [],
          'address'       => { 'id'         => existing_patient.address.id,
                               'updated_at' => Time.zone.now + 10.days },
          'updated_at'    => Time.zone.now + 10.days
        )
      end

      post :sync_from_user, params: { patients: updated_patients }

      updated_patients.each do |updated_patient|
        patient = Patient.find(updated_patient['id'])
        expect(patient.attributes.except('created_at', 'updated_at'))
          .to eq updated_patient
                   .except('address', 'phone_numbers', 'created_at', 'updated_at')
                   .merge('address_id' => updated_patient['address']['id'])

        expect(patient.created_at.to_i).to eq(updated_patient['created_at'].to_i)
        expect(patient.updated_at.to_i).to eq(updated_patient['updated_at'].to_i)

        expect(patient.address.attributes.except('created_at', 'updated_at'))
          .to eq updated_patient['address'].except('created_at', 'updated_at')
        expect(patient.address.created_at.to_i).to eq(updated_patient['address']['created_at'].to_i)
        expect(patient.address.updated_at.to_i).to eq(updated_patient['address']['updated_at'].to_i)

      end
    end

    it 'updates existing patients across users' do
      patient_latest   = FactoryBot.create(:patient)
      patient_outdated = FactoryBot.attributes_for(
        :patient,
        id:         patient_latest.id,
        updated_at: Time.now - 1.day)

      post :sync_from_user, params: { patients: [patient_outdated] }

      db_patient = Patient.find(patient_latest.id)
      expect(db_patient.attributes).to eq(patient_latest.attributes)
    end
  end
end
