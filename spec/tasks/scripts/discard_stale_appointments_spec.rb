require "rails_helper"
require "tasks/scripts/discard_stale_appointments"

RSpec.describe DiscardStaleAppointments do
  context "discard stale appointments for a patient" do
    let(:patient) { create(:patient) }

    it "discards all but the latest scheduled appointments if more than one are present" do
      stale_appointments = create_list(:appointment, 3, patient: patient, status: "scheduled", scheduled_date: 5.days.ago)
      latest_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardStaleAppointments.call(patient: patient)

      expect(patient.latest_scheduled_appointments).to include(latest_appointment)
      expect(patient.latest_scheduled_appointments).not_to include(*stale_appointments)
    end

    it "doesn't discard scheduled appointments if only one is present" do
      latest_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardStaleAppointments.call(patient: patient)

      expect(patient.latest_scheduled_appointments).to include(latest_appointment)
    end

    it "doesn't discard non-scheduled appointments" do
      non_scheduled_appointments = create_list(:appointment, 3, patient: patient, status: %w[cancelled visited].sample, scheduled_date: 5.days.ago)
      latest_appointment = create(:appointment, patient: patient, status: "scheduled", scheduled_date: 10.days.from_now)

      DiscardStaleAppointments.call(patient: patient)

      expect(patient.appointments).to include(*non_scheduled_appointments)
      expect(patient.latest_scheduled_appointments).to include(latest_appointment)
    end
  end
end
