require "rails_helper"
require "tasks/scripts/covid_medication_reminders"

RSpec.describe CovidMedicationReminders do
  it "creates notifications when experiments are enabled, not sunday and in india production" do
    enable_flag(:experiment)
    allow(CountryConfig.current).to receive("[]").with(:name).and_return("India")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return("production")

    expect(Experimentation::MedicationReminderService).to receive(:schedule_daily_notifications)

    Timecop.freeze("1 Jun 2021") do # Not a Sunday
      described_class.call
    end
  end

  it "does not send notifications reminders if experiments aren't enabled" do
    allow(CountryConfig.current).to receive("[]").with(:name).and_return("India")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return("production")

    Timecop.freeze("1 Jun 2021") do # Not a Sunday
      expect { described_class.call }.to raise_error "Experiments are not enabled in this env"
    end
  end

  it "does not send notifications reminders if day is sunday" do
    enable_flag(:experiment)
    allow(CountryConfig.current).to receive("[]").with(:name).and_return("India")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return("production")

    expect(Experimentation::MedicationReminderService).not_to receive(:schedule_daily_notifications)

    Timecop.freeze("6 Jun 2021") do # Not a Sunday
      described_class.call
    end
  end

  it "does not send notifications if env is not india production" do
    enable_flag(:experiment)
    allow(CountryConfig.current).to receive("[]").with(:name).and_return("India")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return("sandbox")

    expect(Experimentation::MedicationReminderService).not_to receive(:schedule_daily_notifications)

    Timecop.freeze("1 Jun 2021") do # Not a Sunday
      described_class.call
    end
  end
end
