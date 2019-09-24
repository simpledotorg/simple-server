require 'rails_helper'

RSpec.describe UpdateUserIdsFromAuditLogsWorker, type: :job do
  include ActiveJob::TestHelper
  let(:appointment_1) { create(:appointment) }
  let(:appointment_log_1) { create(:audit_log, auditable_type: 'Appointment', auditable_id: appointment_1.id, user: appointment_1.user, action: 'create') }
  let(:appointments) { create_list(:appointment, 5) }
  let!(:appointment_logs) do
    appointments.map do |appointment|
      create(:audit_log, auditable_type: 'Appointment', auditable_id: appointment.id, user: appointment.user, action: 'create')
    end
  end
  let(:appointment_log_ids) do
    AuditLog.creation_logs_for_type('Appointment').map do |log|
      { id: log.auditable_id,
        user_id: log.user_id }
    end
  end
  let!(:appointments_without_user_ids) do
    appointments.each do |appointment|
      appointment.update({ user: nil })
      appointment.save
    end
    Appointment.all
  end

  let(:medical_histories) { create_list(:medical_history, 5) }
  let!(:medical_history_logs) do
    medical_histories.map do |medical_history|
      create(:audit_log, auditable_type: 'MedicalHistory', auditable_id: medical_history.id, user: medical_history.user, action: 'create')
    end
  end
  let(:medical_history_log_ids) do
    AuditLog.creation_logs_for_type('MedicalHistory').map do |log|
      { id: log.auditable_id,
        user_id: log.user_id }
    end
  end
  let!(:medical_histories_without_user_ids) do
    medical_histories.each do |medical_history|
      medical_history.update({ user: nil })
      medical_history.save
    end
    MedicalHistory.all
  end

  let(:prescription_drugs) { create_list(:prescription_drug, 5) }
  let!(:prescription_drug_logs) do
    prescription_drugs.map do |prescription_drug|
      create(:audit_log, auditable_type: 'PrescriptionDrug', auditable_id: prescription_drug.id, user: prescription_drug.user, action: 'create')
    end
  end
  let(:prescription_drug_log_ids) do
    AuditLog.creation_logs_for_type('PrescriptionDrug').map do |log|
      { id: log.auditable_id,
        user_id: log.user_id }
    end
  end
  let!(:prescription_drugs_without_user_ids) do
    prescription_drugs.each do |prescription_drug|
      prescription_drug.update({ user: nil })
      prescription_drug.save
    end
    PrescriptionDrug.all
  end

  describe '#perform_async' do
    it 'queues the job on the audit_log_data_queue' do
      expect {
        UpdateUserIdsFromAuditLogsWorker.perform_async(Appointment, [{id: appointment_log_1.auditable_id, user_id: appointment_log_1.user_id}])
      }.to change(Sidekiq::Queues['audit_log_data_queue'], :size).by(1)
      UpdateUserIdsFromAuditLogsWorker.clear
    end
  end

  describe '#perform' do
    it 'updates the user ids for appointments from audit logs' do
      expect(Appointment.all.pluck(:user_id)).to all(eq(nil))

      UpdateUserIdsFromAuditLogsWorker.perform_async(Appointment, appointment_log_ids)
      UpdateUserIdsFromAuditLogsWorker.drain

      expect(Appointment.all.pluck(:user_id)).not_to include(nil)
      appointment_log_ids.each do |appointment_log|
        expect(Appointment.find(appointment_log[:id]).user_id).to eq(appointment_log[:user_id])
      end
    end
  end

  describe '#perform' do
    it 'updates the user ids for medical histories from audit logs' do
      expect(MedicalHistory.all.pluck(:user_id)).to all(eq(nil))

      UpdateUserIdsFromAuditLogsWorker.perform_async(MedicalHistory, medical_history_log_ids)
      UpdateUserIdsFromAuditLogsWorker.drain

      expect(MedicalHistory.all.pluck(:user_id)).not_to include(nil)
      medical_history_log_ids.each do |medical_history_log|
        expect(MedicalHistory.find(medical_history_log[:id]).user_id).to eq(medical_history_log[:user_id])
      end
    end
  end

  describe '#perform' do
    it 'updates the user ids for prescription_drugs from audit logs' do
      expect(PrescriptionDrug.all.pluck(:user_id)).to all(eq(nil))

      UpdateUserIdsFromAuditLogsWorker.perform_async(PrescriptionDrug, prescription_drug_log_ids)
      UpdateUserIdsFromAuditLogsWorker.drain

      expect(PrescriptionDrug.all.pluck(:user_id)).not_to include(nil)
      prescription_drug_log_ids.each do |prescription_drug_log|
        expect(PrescriptionDrug.find(prescription_drug_log[:id]).user_id).to eq(prescription_drug_log[:user_id])
      end
    end
  end
end
