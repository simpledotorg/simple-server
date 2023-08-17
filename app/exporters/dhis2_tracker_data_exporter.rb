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
    puts Dhis2.client.post(
      path: "tracker",
      query_params: { async: false, reportMode: "FULL" },
      payload: {
        trackedEntities: @patients.map do |patient|
          {
            trackedEntityType: "MCPQUTHX1Ze",
            orgUnit: "DiszpKrYNg8",
            enrollments: [
              generate_enrollment(patient)
            ]
          }
        end
      })
  end

  DHIS2_CONFIG = {
    org_units: {
      "Ngelehun CHC" => "DiszpKrYNg8",
    },
    programs: {
      htn_registry: "pMIglSEqPGS"
    },
    program_stages: {
      htn_visit: "anb2cjLx3WM"
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
      orgUnit: DHIS2_CONFIG.dig(:org_units, "Ngelehun CHC"),
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

  def generate_patient_attributes(patient)
    date_of_birth, is_estimated = date_of_birth(patient)
    [
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :consent_to_record_data),
        value: "true"
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :hypertension),
        value: "YES"
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :current_address),
        value: address(patient)
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :date_of_birth),
        value: date_of_birth
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :date_of_birth_estimated),
        value: is_estimated
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :last_name),
        value: patient.full_name
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :first_name),
        # We only have full_name in the patient record;
        value: ""
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :sex),
        value: patient.gender
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :ncd_patient_status),
        value: "ACTIVE"
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :phone_number),
        value: "234232323"
      },
      {
        attribute: DHIS2_CONFIG.dig(:patient_attributes, :treated_for_htn_in_past),
        value: "no"
      }
    ]
  end

  def generate_enrollment(patient)
    {
      program: DHIS2_CONFIG.dig(:programs, :htn_registry),
      orgUnit: DHIS2_CONFIG.dig(:org_units, "Ngelehun CHC"),
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
