# frozen_string_literal: true

class SetUpBangladeshDecemberExperiment < ActiveRecord::Migration[6.1]
  START_TIME = DateTime.parse("1 Dec 2023").beginning_of_day
  END_TIME = DateTime.parse("31 Dec 2023").end_of_day
  CURRENT_PATIENTS_EXPERIMENT = "Current Patient December 2023"
  STALE_PATIENTS_EXPERIMENT = "Stale Patient December 2023"
  PATIENTS_PER_DAY = 5000
  facility_slugs = {
    basrishal_facilities: ["uhc-agailjhara", "uhc-babuganj-facility", "uhc-bakerganj", "uhc-hijla", "uhc-mehendiganj", "uhc-muladi", "uhc-wazirpur"],
    jhalokathi_facilities: ["uhc-kathalia-86845c14-b23d-4578-820a-63eb9628422a", "uhc-nalchity-97cb9397-8ca7-4edb-81ae-2ac8fb1ea93a", "uhc-rajapur-40d0e15a-37c4-4833-8f55-446bb210c457"],
    dhaka_facilities: ["thc-tejgaon-sadar", "uhc-dhamrai", "uhc-dohar", "uhc-nawabganj"],
    shariatpur_facilities: ["uhc-damuddya", "uhc-goshairhat"],
    munshiganj_facilities: ["uhc-sreenagar", "uhc-tongibari", "uhc-sirajdikhan"],
    chattogram_facilities: ["uhc-hathazari", "uhc-fatikchori", "uhc-anwara", "uhc-satkania", "uhc-lohagara", "uhc-patiya", "uhc-rangunia", "uhc-sitakunda", "uhc-chandanaish", "uhc-raozan", "uhc-banshkhali", "uhc-boalkhali", "uhc-karnaphuli", "uhc-mirsharai", "uhc-sandwip"],
    feni_facilities: ["uhc-fulgazi", "uhc-parsuram", "uhc-daganbhuiya", "uhc-sonagazi", "uhc-chhagalniya"],
    netrokona_facilities: ["uhc-atpara", "uhc-barhatta", "uhc-kalmakanda", "uhc-kendua", "uhc-khaliajuri", "uhc-madan", "uhc-mohanganj", "uhc-purbadhala", "uhc-durgapur-dbd6efea-8950-410e-abc3-ed9a329fb9d3"],
    sirajganj_facilities: ["uhc-belkuchi", "uhc-chowhali", "uhc-kamarkhanda", "uhc-kazipur", "uhc-shahzadpur", "uhc-tarash", "uhc-ullapara"],
    pabna_facilities: ["uhc-bera", "uhc-bhangura", "uhc-faridpur", "uhc-iswardi", "uhc-santhia", "uhc-chatmohar", "uhc-sujanagar-4b973cb1-d584-4100-91ca-778f218b502e", "atgharia-upazila-health-complex"],
    jamalpur_facilities: ["uhc-islampur", "uhc-melandah", "uhc-sarishabari", "uhc-dewanganj", "uhc-bakshiganj", "uhc-madarganj"],
    sherpur_facilities: ["uhc-jhenaigati", "uhc-nalitabari", "uhc-nakhla", "uhc-sribordi"]
  }.values.reduce(:+)
  FILTERS = {
    "facilities" => {"include" => facility_slugs}
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
