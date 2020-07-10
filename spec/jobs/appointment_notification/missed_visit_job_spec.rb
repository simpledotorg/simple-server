require "rails_helper"
require "sidekiq/testing"

RSpec.describe AppointmentNotification::MissedVisitJob, type: :job do
  let!(:ihci) { create(:organization, name: "IHCI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:ihci_facility_group) { create(:facility_group, organization: ihci) }
  let!(:path_facility_group) { create(:facility_group, organization: path) }
  let!(:ihci_facility) { create(:facility, facility_group: ihci_facility_group) }
  let!(:path_facility) { create(:facility, facility_group: path_facility_group) }
  let!(:overdue_appointments_from_ihci) { create_list(:appointment, 2, :overdue, facility: ihci_facility) }
  let!(:overdue_appointments_from_path) { create_list(:appointment, 2, :overdue, facility: path_facility) }
  let!(:all_overdue_appointments) { overdue_appointments_from_ihci + overdue_appointments_from_path }

  before do
    allow_any_instance_of(AppointmentNotification::Worker).to receive(:perform)

    allow(FeatureToggle).to receive(:enabled?).with("APPOINTMENT_REMINDERS").and_return(true)
    allow(ENV).to receive(:[]).with("APPOINTMENT_NOTIFICATION_FAN_OUT_BATCH_SIZE").and_return(250)
  end

  it "should send reminders to enabled organizations in env" do
    enabled_organizations = [ihci, path]
    allow(ENV).to receive(:[]).with("APPOINTMENT_NOTIFICATION_ORG_IDS").and_return(enabled_organizations.map(&:id))

    expect(AppointmentNotificationService).to receive(:send_after_missed_visit)
      .exactly(enabled_organizations.count).times do |appointments|
      expect(appointments.count).to eq(2)
    end

    described_class.perform_async(Time.current.hour, Time.current.hour)
    described_class.drain
  end
end
