require "dhis2"

class Dhis2TrackerDataExporter
  DHIS2_CONFIG = YAML.load_file("config/data/dhis2/tracker/sandbox.yml").with_indifferent_access

  def initialize(facility_slug, org_unit_id)
    @facility = Facility.find_by(slug: facility_slug)
    @org_unit_id = org_unit_id

    configure
  end

  def configure
    Dhis2.configure do |config|
      config.url = "https://dhis2-perf.simple.org" # ENV.fetch("DHIS2_URL")
      config.user = "admin" # ENV.fetch("DHIS2_USERNAME")
      config.password = "district" # ENV.fetch("DHIS2_PASSWORD")
    end
  end

  def export_tracked_entities
    no_patients = rand(50..2000)
    patients = @facility.patients.first(no_patients)

    puts "[#{@facility.slug} -> #{@org_unit_id}]: #{patients.count}"

    payload = {
      trackedEntities: patients.map do |patient|
        {
          trackedEntityType: DHIS2_CONFIG.dig(:tracked_entity_types, :person_htn),
          orgUnit: @org_unit_id,
          enrollments: [
            generate_enrollment(patient)
          ]
        }
      end
    }

    response = Dhis2.client.post(
      path: "tracker",
      payload: payload,
      query_params: {skipSideEffects: true}
    )
    [response, patients.count]
  end

  def generate_enrollment(patient)
    {
      program: DHIS2_CONFIG.dig(:programs, :htn_registry),
      orgUnit: @org_unit_id,
      enrolledAt: patient.device_created_at.iso8601,
      attributes: generate_patient_attributes(patient),
      events: patient.blood_pressures.map { |blood_pressure| generate_htn_event(blood_pressure) }
    }
  end

  def generate_patient_attributes(patient)
    first_name, last_name = first_and_last_names(patient.full_name)
    medical_history = patient.medical_history
    [
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :current_address),
        value: address(patient)
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :date_of_birth),
        value: date_of_birth(patient)
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :last_name),
        value: last_name
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :first_name),
        value: first_name
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :sex),
        value: patient.gender
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :ncd_patient_status),
        value: status(patient)
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :phone_number),
        value: patient.phone_numbers&.first&.number
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :receiving_htn_treatment),
        value: medical_history.receiving_treatment_for_hypertension
      }
    ]
  end

  def generate_htn_event(blood_pressure)
    {
      program: DHIS2_CONFIG.dig(:programs, :htn_registry),
      programStage: DHIS2_CONFIG.dig(:program_stages, :htn_visit),
      occurredAt: rand(8.years.ago..blood_pressure.device_created_at).iso8601,
      orgUnit: @org_unit_id,
      dataValues: [
        {
          dataElement: DHIS2_CONFIG.dig(:event_attributes, :systolic),
          value: blood_pressure.systolic
        },
        {
          dataElement: DHIS2_CONFIG.dig(:event_attributes, :diastolic),
          value: blood_pressure.diastolic
        },
        {
          dataElement: DHIS2_CONFIG.dig(:event_attributes, :amlodipine),
          value: ["", "1", "2"].sample
        },
        {
          dataElement: DHIS2_CONFIG.dig(:event_attributes, :losartan),
          value: ["", "1", "2"].sample
        },
        {
          dataElement: DHIS2_CONFIG.dig(:event_attributes, :hydrochlorothiazide),
          value: ["", "1"].sample
        },
        {
          dataElement: DHIS2_CONFIG.dig(:event_attributes, :telmisartan),
          value: ["", "1", "2"].sample
        }
      ]
    }
  end

  def status(patient)
    {
      active: "ACTIVE",
      dead: "DIED",
      migrated: "TRANSFER",
      inactive: "INACTIVE",
      unresponsive: "UNRESPONSIVE"
    }.with_indifferent_access.fetch(patient.status)
  end

  def first_and_last_names(name)
    name.split(" ")
  end

  def date_of_birth(patient)
    patient.date_of_birth || patient.current_age.years.ago.to_date
  end

  def address(patient)
    address = patient.address
    [address.street_address, address.village_or_colony, address.district, address.state, address.pin].join(", ")
  end
end
