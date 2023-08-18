require "dhis2"

class Dhis2TrackerDataExporter
  def initialize(facility_slug, org_unit_id)
    @facility = Facility.find_by(slug: facility_slug)
    @org_unit_id = org_unit_id

    configure
  end

  def configure
    Dhis2.configure do |config|
      # TODO get these from ENV
      config.url = "http://localhost:8080"
      config.user = "admin"
      config.password = "district"
    end
  end

  def config
    YAML.load_file(Rails.root.join("config/data/dhis2/tracker/local.yml")).with_indifferent_access
  end

  def export_tracked_entites
    patients = @facility.patients

    payload = {
      trackedEntities: patients.map do |patient|
        {
          trackedEntityType: config.dig(:tracked_entity_types, :person_htn),
          orgUnit: @org_unit_id,
          enrollments: [
            generate_enrollment(patient)
          ]
        }
      end
    }

    puts Dhis2.client.post(
      path: "tracker",
      payload: payload)

    # TODO: poll report page from response till status OK to return this. also check how many actually succeeded:
    puts "#{patients.count} patients were moved from #{@facility.name} to org unit #{config.dig(:org_units, @facility.id)}"
  end

  def generate_htn_event(blood_pressure)
    {
      program: config.dig(:programs, :htn_registry),
      programStage: config.dig(:program_stages, :htn_visit),
      occurredAt: blood_pressure.device_created_at.iso8601,
      orgUnit: @org_unit_id,
      dataValues: [
        {
          dataElement: config.dig(:event_attributes, :amlodopine),
          value: "1"
        },
        {
          dataElement: config.dig(:event_attributes, :systolic),
          value: blood_pressure.systolic
        },
        {
          dataElement: config.dig(:event_attributes, :lorstan),
          value: "1"
        },
        {
          dataElement: config.dig(:event_attributes, :diastolic),
          value: blood_pressure.diastolic
        },
        {
          dataElement: config.dig(:event_attributes, :bmi_measurement),
          value: "false"
        },
        {
          dataElement: config.dig(:event_attributes, :hydrochlorothiazide),
          value: "1"
        },
        {
          dataElement: config.dig(:event_attributes, :telmisartan),
          value: "1"
        }
      ]
    }
  end

  # Currently ncd_patient_status expects ACTIVE,TRANSFER,DIED.
  # On Simple, we also have inactive and unresponsive
  def status(patient)
    case patient.status
    when :active
      "ACTIVE"
    when :dead
      "DIED"
    else
      "TRANSFER"
    end
  end

  def get_first_and_last_names(name)
    name.split(" ")
  end

  def generate_patient_attributes(patient)
    date_of_birth, is_estimated = date_of_birth(patient)
    first_name, last_name = get_first_and_last_names(patient.full_name)
    medical_history = patient.medical_history
    [
      {
        # We don't have this value on simple
        attribute: config.dig(:patient_attributes, :consent_to_record_data),
        value: "true"
      },
      {
        attribute: config.dig(:patient_attributes, :hypertension),
        value: medical_history.hypertension.upcase
      },
      {
        attribute: config.dig(:patient_attributes, :current_address),
        value: address(patient)
      },
      {
        # calculating this as age years from today's date
        attribute: config.dig(:patient_attributes, :date_of_birth),
        value: date_of_birth
      },
      {
        attribute: config.dig(:patient_attributes, :date_of_birth_estimated),
        value: is_estimated
      },
      {
        # splitting these on " ". need a better way to do this
        attribute: config.dig(:patient_attributes, :last_name),
        value: last_name
      },
      {
        attribute: config.dig(:patient_attributes, :first_name),
        value: first_name
      },
      {
        # this is set to make/female. should add a transgender option
        attribute: config.dig(:patient_attributes, :sex),
        value: patient.gender
      },
      {
        attribute: config.dig(:patient_attributes, :ncd_patient_status),
        value: status(patient)
      },
      {
        attribute: config.dig(:patient_attributes, :ncd_update_patient_status),
        value: "true"
      },
      {
        # on simple, patients can have multiple phone numbers
        attribute: config.dig(:patient_attributes, :phone_number),
        value: patient.phone_numbers&.first&.number
      },
      {
        # These two may not have the same definition
        attribute: config.dig(:patient_attributes, :treated_for_htn_in_past),
        value: medical_history.receiving_treatment_for_hypertension.upcase
      }
    ]
  end

  def generate_enrollment(patient)
    {
      program: config.dig(:programs, :htn_registry),
      orgUnit: @org_unit_id,
      enrolledAt: patient.device_created_at.iso8601,
      attributes: generate_patient_attributes(patient),
      events: patient.blood_pressures.map { |blood_pressure| generate_htn_event(blood_pressure) }
    }
  end

  def date_of_birth(patient)
    date_of_birth = patient.date_of_birth
    is_estimated = false
    if date_of_birth.nil?
      date_of_birth = patient.current_age.years.ago.to_date
      is_estimated = true
    end
    [date_of_birth, is_estimated]
  end

  def address(patient)
    address = patient.address
    [address.street_address, address.village_or_colony, address.district, address.state, address.pin].join(", ")
  end
end
