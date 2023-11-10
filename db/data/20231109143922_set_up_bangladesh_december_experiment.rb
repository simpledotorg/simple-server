# frozen_string_literal: true

class SetUpBangladeshDecemberExperiment < ActiveRecord::Migration[6.1]
  START_TIME = DateTime.parse("1 Dec 2023").beginning_of_day
  END_TIME = DateTime.parse("31 Dec 2023").beginning_of_day
  CURRENT_PATIENTS_EXPERIMENT = "Current Patient December 2023"
  STALE_PATIENTS_EXPERIMENT = "Stale Patient December 2023"
  PATIENTS_PER_DAY = 5000
  facilities = {
    basrishal_facilities: ["uhc-agailjhara", "uhc-babuganj-facility", "uhc-bakerganj", "uhc-hijla", "uhc-mehendiganj", "uhc-muladi", "uhc-wazirpur"],
    jhalokathi_facilities: ["uhc-kathalia-facility", "uhc-nalchity-facility", "uhc-rajapur-facility"],
    dhaka_facilities: ["thc-tejgaon-sadar", "uhc-dhamrai", "uhc-dohar", "uhc-nawabganj"],
    shariatpur_facilities: ["uhc-damuddya", "uhc-goshairhat"],
    munshiganj_facilities: ["uhc-sreenagar", "uhc-tongibari", "uhc-sirajdikhan"],
    chattogram_facilities: ["uhc-anwara", "uhc-banshkhali", "uhc-boalkhali", "uhc-satkania", "uhc-chandanaish", "uhc-karnaphuli", "uhc-lohagara", "uhc-mirsharai", "uhc-patiya", "uhc-rangunia", "uhc-raozan", "uhc-sandwip", "uhc-sitakunda"],
    feni_facilities: ["uhc-fulgazi", "uhc-sonagazi", "uhc-parsuram", "uhc-chhagalniya", "uhc-daganbhuiya"],
    netrakona_facilities: ["uhc-kalmakanda", "uhc-madan", "uhc-barhatta", "uhc-durgapur-facility", "uhc-khaliajuri", "uhc-mohanganj", "uhc-purbadhala", "uhc-kendua", "uhc-atpara", "netrokona-sadar"],
    sirajganj_facilities: ["uhc-belkuchi", "uhc-kazipur", "uhc-shahzadpur", "uhc-ullapara", "uhc-chowhali", "uhc-raiganj", "uhc-kamarkhanda", "uhc-tarash"],
    pabna_facilities: ["uhc-faridpur", "uhc-bera", "uhc-bhangura", "uhc-santhia", "uhc-iswardi", "uhc-chatmohar", "atgharia-upazila-health-complex", "uhc-sujanagar-facility"],
    jamalpur_facilities: ["uhc-islampur", "uhc-melandah", "uhc-sarishabari", "uhc-dewanganj", "uhc-bakshiganj", "uhc-madarganj"],
    sherpur_facilities: ["uhc-jhenaigati", "uhc-nalitabari", "uhc-nakhla", "uhc-sribordi"]
  }.values.reduce(:+)

  FILTERS = {
    "facilities" => {"include" => facilities}
  }.freeze

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    transaction do
      Experimentation::Experiment.current_patients.create!(
        name: CURRENT_PATIENTS_EXPERIMENT,
        start_time: START_TIME,
        end_time: END_TIME,
        max_patients_per_day: PATIENTS_PER_DAY,
        filters: FILTERS
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        cascade1 = experiment.treatment_groups.create!(description: "cascade_official_short")
        cascade1.reminder_templates.create!(message: "notifications.set01.official_short", remind_on_in_days: -1)
        cascade1.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
        cascade1.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)

        cascade2 = experiment.treatment_groups.create!(description: "cascade_free")
        cascade2.reminder_templates.create!(message: "notifications.set01.free", remind_on_in_days: -1)
        cascade2.reminder_templates.create!(message: "notifications.set02.free", remind_on_in_days: 0)
        cascade2.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)

        cascade3 = experiment.treatment_groups.create!(description: "cascade_alarm")
        cascade3.reminder_templates.create!(message: "notifications.set01.alarm", remind_on_in_days: -1)
        cascade3.reminder_templates.create!(message: "notifications.set02.alarm", remind_on_in_days: 0)
        cascade3.reminder_templates.create!(message: "notifications.set03.alarm", remind_on_in_days: 3)

        cascade4 = experiment.treatment_groups.create!(description: "cascade_professional_request")
        cascade4.reminder_templates.create!(message: "notifications.set01.professional_request", remind_on_in_days: -1)
        cascade4.reminder_templates.create!(message: "notifications.set02.professional_request", remind_on_in_days: 0)
        cascade4.reminder_templates.create!(message: "notifications.set03.professional_request", remind_on_in_days: 3)
      end
    end

    transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: STALE_PATIENTS_EXPERIMENT,
        start_time: START_TIME,
        end_time: END_TIME,
        max_patients_per_day: PATIENTS_PER_DAY,
        filters: FILTERS
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        cascade1 = experiment.treatment_groups.create!(description: "cascade_official_short")
        cascade1.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
        cascade1.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
        cascade1.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)

        cascade2 = experiment.treatment_groups.create!(description: "cascade_free")
        cascade2.reminder_templates.create!(message: "notifications.set02.free", remind_on_in_days: 0)
        cascade2.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)
        cascade2.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 7)

        cascade3 = experiment.treatment_groups.create!(description: "cascade_alarm")
        cascade3.reminder_templates.create!(message: "notifications.set02.alarm", remind_on_in_days: 0)
        cascade3.reminder_templates.create!(message: "notifications.set03.alarm", remind_on_in_days: 3)
        cascade3.reminder_templates.create!(message: "notifications.set03.alarm", remind_on_in_days: 7)

        cascade4 = experiment.treatment_groups.create!(description: "cascade_professional_request")
        cascade4.reminder_templates.create!(message: "notifications.set02.professional_request", remind_on_in_days: 0)
        cascade4.reminder_templates.create!(message: "notifications.set03.professional_request", remind_on_in_days: 3)
        cascade4.reminder_templates.create!(message: "notifications.set03.professional_request", remind_on_in_days: 7)
      end
    end
  end

  def down
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    Experimentation::Experiment.current_patients.find_by_name(CURRENT_PATIENTS_EXPERIMENT)&.cancel
    Experimentation::Experiment.stale_patients.find_by_name(STALE_PATIENTS_EXPERIMENT)&.cancel
  end
end
