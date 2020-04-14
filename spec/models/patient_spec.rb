require 'rails_helper'
include Hashable

describe Patient, type: :model do
  subject(:patient) { build(:patient) }

  it 'picks up available genders from country config' do
    expect(described_class::GENDERS).to eq(Rails.application.config.country[:supported_genders])
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:address).optional }
    it { is_expected.to have_many(:phone_numbers) }
    it { is_expected.to have_many(:blood_pressures) }
    it { is_expected.to have_many(:blood_sugars) }
    it { is_expected.to have_many(:prescription_drugs) }
    it { is_expected.to have_many(:facilities).through(:blood_pressures) }
    it { is_expected.to have_many(:appointments) }
    it { is_expected.to have_one(:medical_history) }

    it 'has distinct facilities' do
      patient = FactoryBot.create(:patient)
      facility = FactoryBot.create(:facility)
      FactoryBot.create_list(:blood_pressure, 5, patient: patient, facility: facility)
      expect(patient.facilities.count).to eq(1)
    end

    it { is_expected.to belong_to(:registration_facility).class_name('Facility').optional }
    it { is_expected.to belong_to(:registration_user).class_name('User') }

    it { is_expected.to have_many(:latest_blood_pressures).order(recorded_at: :desc).class_name('BloodPressure') }
    it { is_expected.to have_many(:latest_blood_sugars).order(recorded_at: :desc).class_name('BloodSugar') }

    specify do
      is_expected.to have_many(:latest_scheduled_appointments)
                       .conditions(status: 'scheduled')
                       .order(scheduled_date: :desc)
                       .class_name('Appointment')
    end

    specify do
      is_expected.to have_many(:latest_bp_passports)
                       .conditions(identifier_type: 'simple_bp_passport')
                       .order(device_created_at: :desc)
                       .class_name('PatientBusinessIdentifier')
    end
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'

    it 'validates that date of birth is not in the future' do
      patient = FactoryBot.build(:patient)
      patient.date_of_birth = 3.days.from_now
      expect(patient).to be_invalid
    end
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context 'Scopes' do
    describe '.not_contacted' do
      let(:patient_to_followup) { create(:patient, device_created_at: 5.days.ago) }
      let(:patient_to_not_followup) { create(:patient, device_created_at: 1.day.ago) }
      let(:patient_contacted) { create(:patient, contacted_by_counsellor: true) }
      let(:patient_could_not_be_contacted) { create(:patient, could_not_contact_reason: 'dead') }

      it 'includes uncontacted patients registered 2 days ago or earlier' do
        expect(Patient.not_contacted).to include(patient_to_followup)
      end

      it 'excludes uncontacted patients registered less than 2 days ago' do
        expect(Patient.not_contacted).not_to include(patient_to_not_followup)
      end

      it 'excludes already contacted patients' do
        expect(Patient.not_contacted).not_to include(patient_contacted)
      end

      it 'excludes patients who could not be contacted' do
        expect(Patient.not_contacted).not_to include(patient_could_not_be_contacted)
      end
    end
  end

  context 'Utility methods' do
    let(:patient) { create(:patient) }

    describe '#risk_priority' do
      it 'returns no priority for patients recently overdue' do
        create(:appointment, scheduled_date: 29.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:NONE])
      end

      it 'returns high priority for patients overdue with critical bp' do
        create(:blood_pressure, :critical, patient: patient)
        create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it 'returns high priority for hypertensive bp patients with medical history risks' do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:medical_history, :prior_risk_history, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it 'returns regular priority for patients overdue with only hypertensive bp' do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it 'returns no priority for patients overdue with only medical risk history' do
        create(:medical_history, :prior_risk_history, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:NONE])
      end

      it 'returns regular priority for patients overdue with hypertension' do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it 'returns low priority for patients overdue with low risk' do
        create(:blood_pressure, :under_control, patient: patient)
        create(:appointment, scheduled_date: 2.years.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:LOW])
      end

      it 'returns high priority for patients overdue with high blood sugar' do
        create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 300)
        create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns 'none' priority for patients overdue with normal blood sugar" do
        create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 150)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:NONE])
      end
    end

    describe '#current_age' do
      it 'returns age based on date of birth year if present' do
        patient.date_of_birth = Date.parse('1980-01-01')

        expect(patient.current_age).to eq(Date.current.year - 1980)
      end

      it 'returns age based on age_updated_at if date of birth is not present' do
        patient = create(:patient, age: 30, age_updated_at: 25.months.ago, date_of_birth: nil)

        expect(patient.current_age).to eq(32)
      end

      it 'returns 0 if age is 0' do
        patient.age = 0
        patient.age_updated_at = 2.years.ago

        expect(patient.current_age).to eq(0)
      end
    end

    describe '#latest_phone_number' do
      it 'returns the last phone number for the patient' do
        patient = create(:patient)
        _number_1 = create(:patient_phone_number, patient: patient)
        _number_2 = create(:patient_phone_number, patient: patient)
        number_3 = create(:patient_phone_number, patient: patient)

        expect(patient.reload.latest_phone_number).to eq(number_3.number)
      end
    end

    describe '#latest_mobile_number' do
      it 'returns the last mobile number for the patient' do
        patient = create(:patient)
        number_1 = create(:patient_phone_number, patient: patient)
        _number_2 = create(:patient_phone_number, phone_type: :landline, patient: patient)
        _number_3 = create(:patient_phone_number, phone_type: :invalid, patient: patient)

        expect(patient.reload.latest_mobile_number).to eq(number_1.number)
      end
    end
  end

  context 'Virtual params' do
    describe '#call_result' do
      it 'correctly records successful contact' do
        patient.call_result = 'contacted'

        expect(patient.contacted_by_counsellor).to eq(true)
      end

      Patient.could_not_contact_reasons.values.each do |reason|
        it "correctly records could not contact reason: '#{reason}'" do
          patient.call_result = reason

          expect(patient.could_not_contact_reason).to eq(reason)
        end
      end

      it 'sets patient status if call indicated they died' do
        patient.call_result = 'dead'

        expect(patient.status).to eq('dead')
      end
    end
  end

  context 'anonymised data for patients' do
    describe 'anonymized_data' do
      it 'correctly retrieves the anonymised data for the patient' do
        anonymised_data =
          { id: hash_uuid(patient.id),
            created_at: patient.created_at,
            registration_date: patient.recorded_at,
            registration_facility_name: patient.registration_facility.name,
            user_id: hash_uuid(patient.registration_user.id),
            age: patient.age,
            gender: patient.gender }

        expect(patient.anonymized_data).to eq anonymised_data
      end
    end
  end

  context '.discard_data' do
    before do
      create_list(:prescription_drug, 2, patient: patient)
      create(:medical_history, patient: patient)
      create_list(:appointment, 2, patient: patient)
      bps = create_list(:blood_pressure, 2, patient: patient)
      sugars = create_list(:blood_sugar, 2, patient: patient)
      (bps + sugars).each do |record|
        create(:encounter,
               :with_observables,
               patient: patient,
               observable: record,
               facility: patient.registration_facility)
      end
    end

    it "should discard a patient's address" do
      patient.discard_data
      expect(patient.address).to be_discarded
      expect(Address.find_by(id: patient.address.id)).to be nil
    end

    it "should discard a patient's medical history" do
      patient.discard_data
      expect(patient.medical_history).to be_discarded
      expect(MedicalHistory.find_by(id: patient.medical_history.id)).to be nil
    end

    specify { expect { patient.discard_data }.to change { patient.appointments.count }.by(-2) }
    specify { expect { patient.discard_data }.to change { patient.blood_pressures.count }.by(-2) }
    specify { expect { patient.discard_data }.to change { patient.blood_sugars.count }.by(-2) }
    specify { expect { patient.discard_data }.to change { patient.business_identifiers.count }.by(-1) }
    specify { expect { patient.discard_data }.to change { patient.encounters.count }.by(-4) }
    specify { expect { patient.discard_data }.to change { patient.phone_numbers.count }.by(-1) }
    specify { expect { patient.discard_data }.to change { patient.observations.count }.by(-4) }
    specify { expect { patient.discard_data }.to change { patient.prescription_drugs.count }.by(-2) }
    specify { expect { patient.discard_data }.to change { Patient.count }.by(-1) }
  end
end
