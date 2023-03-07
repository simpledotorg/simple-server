require "rails_helper"
require Rails.root.join("db", "data", "20230306143819_setup_one_off_medication_reminders_bangladesh")

RSpec.describe SetupOneOffMedicationRemindersBangladesh do
  it "sets up the current notifications" do
    allow(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")
    stub_const("SetupOneOffMedicationRemindersBangladesh::PATIENTS_PER_DAY", 2)
    create_list(:patient, 5)
    create_list(:patient, 2, facility_id: "2e7a4917-be56-4d2e-aee6-4c9738ab8a9b")

    described_class.new.up

    expect(Notification.count).to eq(5)
    expect(Notification.pluck(:status)).to all eq("scheduled")
    expect(Notification.pluck(:message)).to all eq("notifications.one_off_medications_reminder")
    expect(Notification.pluck(:purpose)).to all eq("one_off_medications_reminder")
    expect(Notification.order(:remind_on).pluck(:remind_on)).to eq [
      1.days.from_now.to_date,
      1.days.from_now.to_date,
      2.days.from_now.to_date,
      2.days.from_now.to_date,
      3.days.from_now.to_date
    ]
  end
end
