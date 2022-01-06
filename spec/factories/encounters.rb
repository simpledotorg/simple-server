# frozen_string_literal: true

FactoryBot.define do
  factory :encounter do
    id { SecureRandom.uuid }

    association :patient, strategy: :create
    association :facility, strategy: :create

    transient do
      observable { create(:blood_pressure) }
    end

    trait(:with_observables) do
      observations do
        [build(:observation,
          encounter_id: id,
          observable: observable,
          observable_type: observable.class.name,
          user: observable.user)]
      end
      facility { observable.facility }
      patient { observable.patient }
      encountered_on { observable.recorded_at.to_date }
    end

    encountered_on { "2019-09-11" }

    timezone_offset { 0 }
    metadata { nil }
    notes { "" }

    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_encounters_payload(encounter = FactoryBot.build(:encounter))
  encounter.attributes.with_payload_keys
    .merge({observations: {blood_pressures: encounter.blood_pressures.map do |bp|
                                              bp.attributes.with_payload_keys
                                            end}}.with_indifferent_access)
end

def build_invalid_encounters_payload
  encounter = build_encounters_payload
  encounter["created_at"] = nil
  encounter["facility_id"] = nil
  encounter
end

def updated_encounters_payload(existing_encounter)
  update_time = 10.days.from_now
  build_encounters_payload(existing_encounter).merge(
    "updated_at" => update_time,
    "systolic" => rand(80..240)
  )
end

def associate_encounter(observable)
  encountered_on = Encounter.generate_encountered_on(observable.recorded_at, Time.find_zone(Period::REPORTING_TIME_ZONE).utc_offset)
  encounter_id = Encounter.generate_id(observable.facility_id, observable.patient_id, encountered_on)

  Encounter.find_by(id: encounter_id) || create(:encounter,
    id: encounter_id,
    patient: observable.patient,
    observable: observable,
    facility: observable.facility,
    encountered_on: encountered_on)

  create(:observation,
    encounter_id: encounter_id,
    observable: observable,
    observable_type: observable.class.name,
    user: observable.user)
end
