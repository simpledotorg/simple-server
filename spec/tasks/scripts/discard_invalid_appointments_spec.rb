# frozen_string_literal: true

require "rails_helper"
require "tasks/scripts/discard_invalid_appointments"

RSpec.describe DiscardInvalidAppointments do
  context "old and upcoming appointments" do
    let(:patient) { create(:patient) }

    it "discards all but the latest scheduled appointment" do
      invalid_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 5.days.ago)
      latest_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.latest_scheduled_appointments).to contain_exactly(latest_appointment)
      expect(patient.latest_scheduled_appointments).not_to include(*invalid_appointments)
    end

    it "doesn't discard scheduled appointments if only one is present" do
      latest_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.latest_scheduled_appointments).to contain_exactly(latest_appointment)
    end

    it "doesn't discard non-scheduled appointments" do
      non_scheduled_appointments = create_list(:appointment, 3, patient: patient, status: %w[cancelled visited].sample, scheduled_date: 5.days.ago)
      latest_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.appointments).to include(*non_scheduled_appointments)
      expect(patient.latest_scheduled_appointments).to contain_exactly(latest_appointment)
    end
  end

  context "far future appointments" do
    let(:patient) { create(:patient) }

    it "discards far future appointments (> 31 days) in favour of a near future appointment" do
      future_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 35.days.from_now)
      valid_future_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.latest_scheduled_appointments).to contain_exactly(valid_future_appointment)
      expect(patient.latest_scheduled_appointments).not_to include(*future_appointments)
    end

    it "mutates a far future appointment (> 31 days) if no other scheduled appointments are present" do
      future_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 35.days.from_now)
      last_future_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 45.days.from_now)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.latest_scheduled_appointments.pluck(:id)).to contain_exactly(last_future_appointment.id)
      expect(patient.latest_scheduled_appointment.scheduled_date).to eq(Date.today + 31.days)
      expect(patient.latest_scheduled_appointments).not_to include(*future_appointments)
    end
  end

  context "both old and future appointments are present" do
    let(:patient) { create(:patient) }

    it "discards far future appointments (> 31 days) and old appointments in favour of an upcoming appointment" do
      future_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 35.days.from_now)
      old_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 2.months.ago)
      valid_future_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.latest_scheduled_appointments).to contain_exactly(valid_future_appointment)
      expect(patient.latest_scheduled_appointments).not_to include(*future_appointments)
      expect(patient.latest_scheduled_appointments).not_to include(*old_appointments)
    end

    it "discards far future appointments and keeps the latest old appointment when no upcoming appointment is present" do
      future_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 35.days.from_now)
      old_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 2.months.ago)
      latest_old_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 1.month.ago)

      DiscardInvalidAppointments.call(patient: patient, dry_run: false)

      expect(patient.latest_scheduled_appointments).to contain_exactly(latest_old_appointment)
      expect(patient.latest_scheduled_appointments).not_to include(*future_appointments)
      expect(patient.latest_scheduled_appointments).not_to include(*old_appointments)
    end
  end
end
