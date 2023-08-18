require "dhis2"

class Dhis2TrackerDataExporter
  def initialize(facility)
    @facility = facility
    @patients = @facility.patients

    configure
  end

  def configure
    Dhis2.configure do |config|
      config.url = "http://localhost:8080"
      config.user = "admin"
      config.password = "district"
    end
  end

  def export_tracked_entites
    payload = {
      trackedEntities: @patients.map do |patient|
        {
          trackedEntityType: DHIS2_CONFIG.dig(:tracked_entity_types, :person_htn),
          orgUnit: DHIS2_CONFIG.dig(:org_units, @facility.id),
          enrollments: [
            generate_enrollment(patient)
          ]
        }
      end
    }

    puts Dhis2.client.post(
      path: "tracker",
      payload: payload)

    # TODO: poll report page from response till status OK to return this:
    puts "#{@patients.count} patients were moved from #{@facility.name} to org unit #{DHIS2_CONFIG.dig(:org_units, @facility.id)}"
  end

  DHIS2_CONFIG = {
    org_units: {
      "1884bcc2-5a74-477f-9def-5d3e78c077bf" => "ueuQlqb8ccl",
      "619286e9-d3fa-4a0d-b98d-7ecc9ed2e18a" => "Rp268JB6Ne4",
      "b57b2003-fb6a-4082-b5ea-fa8a8cf67958" => "cDw53Ej8rju",
      "eb23c39e-f9a2-4bce-ac16-e8c712390ce4" => "GvFqTavdpGE",
      "40682518-19b9-4a89-a0b4-5bfd07514ec1" => "plnHVbJR6p4",
      "2d1e5efc-0800-462c-92c2-fa06272d754e" => "BV4IomHvri4",
      "dd79a6fa-e44c-40dc-9807-acfd4d2a1b8d" => "qjboFI0irVu",
      "bcd6e0cb-2196-4a37-8bc3-c37d0f24ef50" => "dWOAzMcK2Wt",
      "c92e00df-b6b4-4987-b7a0-21757233e07f" => "kbGqmM6ZWWV",
      "c9de906f-4fa6-432e-85d8-f68303e22ed9" => "eoYV2p74eVz",
      "7715cd89-2b2e-4cd9-b415-0f3341b4a3df" => "nq7F0t1Pz6t",
      "85e22fc6-f2ed-4feb-b959-353c0d7211c7" => "r5WWF9WDzoa",
      "0c3d86e7-adbc-423b-bf9e-cf0b0c98658d" => "yMCshbaVExv",
      "1be8fb26-87bb-44d7-be5e-0d65304c550e" => "tlMeFk8C4CG",
      "e150046d-5dae-41a5-b321-6e498320fb22" => "BH7rDkWjUqc",
      "2249b9ce-5b41-48af-8849-e31ddee88ff7" => "Rll4VmTDRiE",
      "da5215c8-92ae-44b6-9438-dc07ae81cfd6" => "XtuhRhmbrJM",
      "a5ec1dc8-008e-4d4b-bbbd-6f10f67b8d5b" => "c41XRVOYNJm"
    },
    programs: {
      htn_registry: "pMIglSEqPGS"
    },
    program_stages: {
      htn_visit: "anb2cjLx3WM"
    },
    tracked_entity_types: {
      person_htn: "MCPQUTHX1Ze"
    },
    event_attributes: {
      systolic: "IxEwYiq1FTq",
      diastolic: "yNhtHKtKkO1",
      amlodopine: "eGY7e5Ttbys",
      lorstan: "yUYbcCXo9Mv",
      bmi_measurement: "MzmFoPLwmSt",
      hydrochlorothiazide: "D8FWXAtCuL2",
      telmisartan: "lWmOLo5hFYQ"
    },
    patient_attributes: {
      consent_to_record_data: "YJGACwhN0St",
      hypertension: "jCRIT4GMMOS",
      current_address: "A6Hb0Kvg4vb",
      date_of_birth: "NI0QRzJvQ0k",
      date_of_birth_estimated: "Z1rLc1rVHK8",
      last_name: "ENRjVGxVL6l",
      first_name: "sB1IHYu2xQT",
      sex: "oindugucx72",
      ncd_patient_status: "fI1P3Mg1zOZ",
      ncd_update_patient_status: "D917mo9Whvn",
      phone_number: "YRDy9xy9jD0",
      treated_for_htn_in_past: "l5yxkxHgTw9",
    }
  }.freeze
  EVENT_ATTRIBUTES = DHIS2_CONFIG[:event_attributes]

  def generate_htn_event(blood_pressure)
    {
      program: DHIS2_CONFIG.dig(:programs, :htn_registry),
      programStage: DHIS2_CONFIG.dig(:program_stages, :htn_visit),
      occurredAt: blood_pressure.device_created_at.iso8601,
      orgUnit: DHIS2_CONFIG.dig(:org_units, @facility.id),
      dataValues: [
        {
          dataElement: EVENT_ATTRIBUTES[:amlodopine],
          value: "1"
        },
        {
          dataElement: EVENT_ATTRIBUTES[:systolic],
          value: blood_pressure.systolic
        },
        {
          dataElement: EVENT_ATTRIBUTES[:lorstan],
          value: "1"
        },
        {
          dataElement: EVENT_ATTRIBUTES[:diastolic],
          value: blood_pressure.diastolic
        },
        {
          dataElement: EVENT_ATTRIBUTES[:bmi_measurement],
          value: "false"
        },
        {
          dataElement: EVENT_ATTRIBUTES[:hydrochlorothiazide],
          value: "1"
        },
        {
          dataElement: EVENT_ATTRIBUTES[:telmisartan],
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
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :consent_to_record_data),
        value: "true"
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :hypertension),
        value: medical_history.hypertension.upcase
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :current_address),
        value: address(patient)
      },
      {
        # calculating this as age years from today's date
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :date_of_birth),
        value: date_of_birth
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :date_of_birth_estimated),
        value: is_estimated
      },
      {
        # splitting these on " ". need a better way to do this
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :last_name),
        value: last_name
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :first_name),
        value: first_name
      },
      {
        # this is set to make/female. should add a transgender option
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :sex),
        value: patient.gender
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :ncd_patient_status),
        value: status(patient)
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :ncd_update_patient_status),
        value: "true"
      },
      {
        # on simple, patients can have multiple phone numbers
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :phone_number),
        value: patient.phone_numbers&.first&.number
      },
      {
        # These two may not have the same definition
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :treated_for_htn_in_past),
        value: medical_history.receiving_treatment_for_hypertension.upcase
      }
    ]
  end

  def generate_enrollment(patient)
    {
      program: DHIS2_CONFIG.dig(:programs, :htn_registry),
      orgUnit: DHIS2_CONFIG.dig(:org_units, @facility.id),
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
