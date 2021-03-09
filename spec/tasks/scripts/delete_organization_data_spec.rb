require "rails_helper"
require "tasks/scripts/delete_organization_data"

RSpec.describe DeleteOrganizationData do
  describe ".call" do
    context "disabled" do
      before do
        stub_const("DeleteOrganizationData::DISABLE", true)
      end

      let!(:organization) { create(:organization) }

      it "halts execution" do
        expect {
          described_class.call(organization: organization, dry_run: false)
        }.to raise_error(RuntimeError, "This script is currently disabled, to enable it, raise a PR and make necessary code changes.")
      end
    end

    context "enabled" do
      before do
        stub_const("DeleteOrganizationData::DISABLE", false)
      end

      let!(:organization) { create(:organization) }
      let!(:facility_group) { create(:facility_group, organization: organization) }
      let!(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
      let!(:soft_deleted_facilities) { create_list(:facility, 2, facility_group: facility_group, facility_type: "Standalone", deleted_at: Time.current) }

      let!(:patients) { facilities.map { |facility| create_list(:patient, 2, registration_facility: facility) }.flatten }
      let!(:medical_histories) { patients.map(&:medical_history) }
      let!(:prescription_drugs) { patients.map(&:prescription_drugs).flatten }
      let!(:patient_phone_numbers) { patients.map(&:phone_numbers).flatten }
      let!(:blood_pressures) { patients.map { |patient| create_list(:blood_pressure, 2, :with_encounter, patient: patient, facility: facilities.second) }.flatten }
      let!(:blood_sugars) { patients.map { |patient| create_list(:blood_sugar, 2, :with_encounter, patient: patient, facility: facilities.first) }.flatten }
      let!(:encounters) { [*blood_pressures.map(&:encounter), *blood_sugars.map(&:encounter)] }
      let!(:observations) { [*blood_pressures.map(&:observation), *blood_sugars.map(&:observation)] }
      let!(:appointments) { patients.map { |patient| create_list(:appointment, 2, patient: patient, facility: facilities.first) }.flatten }
      let!(:app_users) { create_list(:user, 2, :with_phone_number_authentication, registration_facility: facilities.first) }
      let!(:dashboard_users) { create_list(:admin, 2, organization: organization) }

      before { allow_any_instance_of(described_class).to receive(:log) }

      it "deletes an org and associated data" do
        described_class.call(organization: organization, dry_run: false)

        facilities.each { |facility| expect { facility.reload }.to raise_error ActiveRecord::RecordNotFound }
        soft_deleted_facilities.each { |facility| expect { facility.reload }.to raise_error ActiveRecord::RecordNotFound }

        patients.each { |patient| expect { patient.reload }.to raise_error ActiveRecord::RecordNotFound }
        appointments.each { |appointment| expect { appointment.reload }.to raise_error ActiveRecord::RecordNotFound }
        blood_pressures.each { |blood_pressure| expect { blood_pressure.reload }.to raise_error ActiveRecord::RecordNotFound }
        blood_sugars.each { |blood_sugar| expect { blood_sugar.reload }.to raise_error ActiveRecord::RecordNotFound }
        encounters.each { |encounter| expect { encounter.reload }.to raise_error ActiveRecord::RecordNotFound }
        observations.each { |observation| expect { observation.reload }.to raise_error ActiveRecord::RecordNotFound }
        medical_histories.each { |medical_history| expect { medical_history.reload }.to raise_error ActiveRecord::RecordNotFound }
        prescription_drugs.each { |prescription_drug| expect { prescription_drug.reload }.to raise_error ActiveRecord::RecordNotFound }
        patient_phone_numbers.each { |patient_phone_number| expect { patient_phone_number.reload }.to raise_error ActiveRecord::RecordNotFound }

        app_users.each { |app_user| expect { app_user.reload }.to raise_error ActiveRecord::RecordNotFound }
        dashboard_users.each { |dashboard_user| expect { dashboard_user.reload }.to raise_error ActiveRecord::RecordNotFound }
      end

      it "does not delete things from other orgs" do
        other_organizations = create_list(:organization, 2)
        other_facility_groups = other_organizations.map { |org| create_list(:facility_group, 2, organization: org) }.flatten
        other_facilities = other_facility_groups.map { |fg| create_list(:facility, 2, facility_group: fg) }.flatten
        other_soft_deleted_facilities = create_list(:facility, 2, deleted_at: Time.current)
        other_patients = other_facilities.map { |facility| create_list(:patient, 2, registration_facility: facility) }.flatten
        other_medical_histories = other_patients.map(&:medical_history)
        other_prescription_drugs = other_patients.map(&:prescription_drugs).flatten
        other_patient_phone_numbers = other_patients.map(&:phone_numbers).flatten
        other_blood_pressures = other_patients.map { |patient| create_list(:blood_pressure, 2, :with_encounter, patient: patient, facility: other_facilities.second) }.flatten
        other_blood_sugars = other_patients.map { |patient| create_list(:blood_sugar, 2, :with_encounter, patient: patient, facility: other_facilities.first) }.flatten
        other_encounters = [*other_blood_pressures.map(&:encounter), *other_blood_sugars.map(&:encounter)]
        other_observations = [*other_blood_pressures.map(&:observation), *other_blood_sugars.map(&:observation)]
        other_appointments = other_patients.map { |patient| create_list(:appointment, 2, patient: patient, facility: other_facilities.first) }.flatten

        other_app_users = create_list(:user, 2, :with_phone_number_authentication, registration_facility: other_facilities.first)
        other_dashboard_users = create_list(:admin, 2, organization: other_organizations.first)

        described_class.call(organization: organization, dry_run: false)
        other_organizations.map { |org| expect(org.reload).to eq org }
        other_facility_groups.map { |fg| expect(fg.reload).to eq fg }
        other_facilities.each { |facility| expect(facility.reload).to eq facility }
        other_soft_deleted_facilities.each { |facility| expect(facility.reload).to eq facility }

        other_patients.each { |patient| expect(patient.reload).to eq patient }
        other_appointments.each { |appointment| expect(appointment.reload).to eq appointment }
        other_blood_pressures.each { |blood_pressure| expect(blood_pressure.reload).to eq blood_pressure }
        other_blood_sugars.each { |blood_sugar| expect(blood_sugar.reload).to eq blood_sugar }
        other_encounters.each { |encounter| expect(encounter.reload).to eq encounter }
        other_observations.each { |observation| expect(observation.reload).to eq observation }
        other_medical_histories.each { |medical_history| expect(medical_history.reload).to eq medical_history }
        other_prescription_drugs.each { |prescription_drug| expect(prescription_drug.reload).to eq prescription_drug }
        other_patient_phone_numbers.each { |patient_phone_number| expect(patient_phone_number.reload).to eq patient_phone_number }

        other_app_users.each { |app_user| expect(app_user.reload).to eq app_user }
        other_dashboard_users.each { |dashboard_user| expect(dashboard_user.reload).to eq dashboard_user }
      end
    end
  end
end
