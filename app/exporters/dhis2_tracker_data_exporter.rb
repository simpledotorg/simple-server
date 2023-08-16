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

  def generate_htn_event(blood_pressure)
    {
      program: "pMIglSEqPGS",
      programStage: "anb2cjLx3WM",
      occurredAt: blood_pressure.device_created_at.iso8601,
      orgUnit: "DiszpKrYNg8",
      dataValues: [
        {
          # amlodopine
          dataElement: "eGY7e5Ttbys",
          value: "1"
        },
        {
          # systolic
          dataElement: "IxEwYiq1FTq",
          value: blood_pressure.systolic
        },
        {
          # Losartan
          dataElement: "yUYbcCXo9Mv",
          value: "1"
        },
        {
          # Diastolic
          dataElement: "yNhtHKtKkO1",
          value: blood_pressure.diastolic
        },
        {
          # BMI Measurement
          dataElement: "MzmFoPLwmSt",
          value: "false"
        },
        {
          # Hydrochlorothiazide
          dataElement: "D8FWXAtCuL2",
          value: "1"
        },
        {
          # Telmisartan
          dataElement: "lWmOLo5hFYQ",
          value: "1"
        }
      ]
    }
  end

  def generate_patient_attributes(patient)
    [
      {
        attribute: "YJGACwhN0St",
        value: "true"
      },
      {
        attribute: "jCRIT4GMMOS",
        value: "YES"
      },
      {
        attribute: "A6Hb0Kvg4vb",
        value: "Random"
      },
      {
        attribute: "NI0QRzJvQ0k",
        value: if not patient.date_of_birth.nil?
                 patient.date_of_birth
               else
                 patient.current_age.years.ago.to_date
               end
      },
      {
        attribute: "Z1rLc1rVHK8",
        value: "true"
      },
      {
        attribute: "ENRjVGxVL6l",
        value: patient.full_name
      },
      {
        attribute: "sB1IHYu2xQT",
        # We only have full_name in the patient record;
        value: ""
      },
      {
        attribute: "oindugucx72",
        value: "MALE"
      },
      {
        attribute: "fI1P3Mg1zOZ",
        value: "ACTIVE"
      },
      {
        attribute: "D917mo9Whvn",
        value: "true"
      },
      {
        attribute: "YRDy9xy9jD0",
        value: "234232323"
      },
      {
        attribute: "l5yxkxHgTw9",
        value: "no"
      }
    ]
  end

  def generate_enrollment(patient)
    {
      program: "pMIglSEqPGS",
      orgUnit: "DiszpKrYNg8",
      enrolledAt: patient.device_created_at.iso8601,
      attributes: generate_patient_attributes(patient),
      events: patient.blood_pressures.map { |blood_pressure| generate_htn_event(blood_pressure) }
    }
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
end
