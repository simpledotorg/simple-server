require "dhis2"
class Dhis2TrackerDataExporter
  def self.configure
    Dhis2.configure do |config|
      config.url = "http://localhost:8080"
      config.user = "admin"
      config.password = "district"
    end
  end

  def generate_htn_event(device_created_at:, org_unit:, diastolic:, systolic:)
    {
      program: "pMIglSEqPGS",
      programStage: "anb2cjLx3WM",
      occurredAt: device_created_at,
      orgUnit: org_unit,
      dataValues: [
        {
          # amlodopine
          dataElement: "eGY7e5Ttbys",
          value: "1"
        },
        {
          # systolic
          dataElement: "IxEwYiq1FTq",
          value: systolic
        },
        {
          # Losartan
          dataElement: "yUYbcCXo9Mv",
          value: "1"
        },
        {
          # Diastolic
          dataElement: "yNhtHKtKkO1",
          value: diastolic
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

  def self.generate_patient_attributes(patient)
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
        value: patient.date_of_birth
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
        attribute: "l5yxkxHgTw9", value: "no"
      }
    ]
  end

  def generate_data(patient)
    patient.blood_pressure.map { |bp| bp.slice(:systolic, :diastolic, :device_created_at) }
  end

  def self.execute
    puts "-----------------------------------"
    puts configure
    puts "-----------|configured|------------"

    patient = Patient.first

    puts Dhis2.client.post(path: "tracker", query_params: {async: false, reportMode: "FULL"}, payload: {
      trackedEntities: [
        {
          trackedEntityType: "MCPQUTHX1Ze",
          orgUnit: "YgcCeCbmTET",
          enrollments: [
            {
              program: "pMIglSEqPGS",
              orgUnit: "YgcCeCbmTET",
              enrolledAt: patient.device_created_at,
              attributes: generate_patient_attributes(patient),
              events: [
                {
                  program: "pMIglSEqPGS",
                  programStage: "anb2cjLx3WM",
                  occurredAt: "2023-07-10T00:00:00.000",
                  orgUnit: "YgcCeCbmTET",
                  dataValues: [
                    {
                      dataElement: "eGY7e5Ttbys",
                      value: "1"
                    },
                    {
                      dataElement: "IxEwYiq1FTq",
                      value: "120"
                    },
                    {
                      dataElement: "yUYbcCXo9Mv",
                      value: "1"
                    },
                    {
                      dataElement: "yNhtHKtKkO1",
                      value: "90"
                    },
                    {
                      dataElement: "MzmFoPLwmSt",
                      value: "false"
                    },
                    {
                      dataElement: "D8FWXAtCuL2",
                      value: "1"
                    },
                    {
                      dataElement: "lWmOLo5hFYQ",
                      value: "1"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    })
  end
end
