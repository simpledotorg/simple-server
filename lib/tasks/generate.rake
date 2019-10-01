require 'yaml'
require 'factory_bot_rails'
require 'faker'
require 'timecop'

# add entropy of 100ms to 1s
def time_entropy(time = Time.now)
  time + SecureRandom.random_number(1 << 12) + 100
end

namespace :generate do
  desc 'Generate realistic seed data for development and testing'
  namespace :seed do
    task :generate_data, [:number_of_months] => :environment do |_t, args|
      number_of_months = args.fetch(:number_of_months) { 3 }.to_i
      environment = ENV.fetch('SIMPLE_SERVER_ENV') { 'development' }
      config = YAML.load_file('config/seed.yml').dig(environment)

      Rails.logger.info("Creating seed data for environment \"#{environment}\" for a period of #{number_of_months} month(s)")

      if environment == 'development'
        Rails.logger.info("Detected development environment. Creating organization hierarchy first...")

        truncate_db
        Rails.logger.info("Truncated database")

        FactoryBot.create(:admin, email: "admin@simple.org", password: 123456, role: 'owner')
        Rails.logger.info("Created login admin (admin@simple.org/123456)")

        create_protocols_and_protocol_drugs(config)
        create_organizations(number_of_months.months.ago, config)

        number_of_months.downto(1) do |month_number|
          creation_date = month_number.months.ago.beginning_of_month

          Organization.all.each do |organization|
            create_organization_patient_records(organization, creation_date, config)
          end
        end
      end

      create_seed_data(number_of_months, config)

      Rails.logger.info("Finished generating seed data for #{ENV.fetch('SIMPLE_SERVER_ENV')}")
    end

    def create_seed_data(number_of_months, config)
      number_of_months.downto(1) do |month_number|
        creation_date = month_number.months.ago.beginning_of_month

        Organization.all.flat_map(&:users).each do |user|
          create_patients(user, creation_date, config)
        end
      end
    end

    def create_protocols_and_protocol_drugs(config)
      config.fetch('protocols').times do
        protocol = FactoryBot.create(:protocol)

        config.fetch('protocol_drugs').times do
          FactoryBot.create(:protocol_drug, protocol: protocol)
        end
      end

      Rails.logger.info("Created protocols and protocol drugs")
    end

    def create_organization_patient_records(organization, date, config)
      facility_groups = organization.facility_groups

      is_hypertensive = get_traits_for_property(config, 'patients').include?('hypertensive')

      facility_groups.flat_map(&:facilities).flat_map(&:registered_patients).each do |patient|
        create_blood_pressures(patient, date, config, is_hypertensive)
      end

      number_of_patients = config.dig('patients', 'count')
      facility_groups.flat_map(&:users).each do |user|
        number_of_patients.times do
          create_patients(user, date, config)
        end
      end
    end

    def create_patients(user, creation_date, config)
      number_of_patients = config.dig('patients', 'count')

      number_of_patients.times do
        time = time_entropy(creation_date)
        patient = FactoryBot.create(:patient, registration_facility: user.registration_facility,
                                    registration_user: user,
                                    created_at: time,
                                    updated_at: time,
                                    age_updated_at: time,
                                    device_created_at: time,
                                    device_updated_at: time)

        if patient.age.nil?
          patient.age = rand(18..100)
          patient.date_of_birth = nil
          patient.save
        end

        patient_traits = get_traits_for_property(config, 'patients')
        is_hypertensive = patient_traits.include?('hypertensive')

        create_medical_history(patient, time, config)
        create_prescription_drugs(patient, time, config)
        create_blood_pressures(patient, time, config, is_hypertensive)
        create_appointments(patient, time, config)

        create_call_logs(patient, time)
        create_exotel_phone_number_detail(patient, time)
      end

      Rails.logger.info("Created patients for date #{creation_date}")
    end

    def create_medical_history(patient, creation_date, config)
      number_of_medical_histories = config.dig('patients', 'medical_histories')

      number_of_medical_histories.times do
        time = time_entropy(creation_date)
        FactoryBot.create(:medical_history, :unknown,
                          patient: patient,
                          created_at: time,
                          updated_at: time,
                          device_created_at: time,
                          device_updated_at: time)

        time = time_entropy(creation_date)
        FactoryBot.create(:medical_history, :prior_risk_history,
                          patient: patient,
                          created_at: time,
                          updated_at: time,
                          device_created_at: time,
                          device_updated_at: time)
      end

      Rails.logger.info("Created medical histories for date #{creation_date}")
    end

    def create_prescription_drugs(patient, creation_date, config)
      number_of_prescription_drugs = config.dig('patients', 'prescription_drugs')

      number_of_prescription_drugs.times do
        time = time_entropy(creation_date)
        FactoryBot.create(:prescription_drug, patient: patient,
                          facility: patient.registration_facility,
                          created_at: time,
                          updated_at: time,
                          device_created_at: time,
                          device_updated_at: time)
      end

      Rails.logger.info("Created Prescription Drugs for date #{creation_date}")
    end

    def create_blood_pressures(patient, creation_date, config, is_hypertensive)
      number_of_blood_pressures = config.dig('patients', 'blood_pressures')

      number_of_blood_pressures.times do
        time = time_entropy(creation_date)
        FactoryBot.create(:blood_pressure,
                          :under_control,
                          device_created_at: time,
                          device_updated_at: time,
                          recorded_at: time,
                          created_at: time,
                          updated_at: time,
                          patient: patient)

        [:high, :very_high, :critical].each do |bp_type|
          time = time_entropy(creation_date)
          FactoryBot.create(:blood_pressure,
                            bp_type,
                            device_created_at: time,
                            device_updated_at: time,
                            recorded_at: time,
                            created_at: time,
                            updated_at: time,
                            patient: patient) if is_hypertensive
        end
      end

      Rails.logger.info("Created blood pressures for date #{creation_date}")
    end

    def create_appointments(patient, creation_date, config)
      number_of_appointments = config.dig('patients', 'appointments')

      Timecop.travel(creation_date) do
        number_of_appointments.times do
          time = time_entropy
          future_date = (30..60).to_a.sample.days.from_now

          FactoryBot.create(:appointment,
                            patient: patient,
                            facility: patient.registration_facility,
                            created_at: time,
                            updated_at: time,
                            scheduled_date: future_date,
                            device_created_at: time,
                            device_updated_at: time)

          time = time_entropy
          FactoryBot.create(:appointment,
                            :overdue,
                            patient: patient,
                            facility: patient.registration_facility,
                            created_at: time,
                            updated_at: time,
                            device_created_at: time,
                            device_updated_at: time)
        end
      end

      Rails.logger.info("Created appointments for date #{creation_date}")
    end

    def create_call_logs(patient, creation_date)
      caller_phone_number = patient.registration_user.phone_number_authentications.first.phone_number
      callee_phone_number = patient.phone_numbers.first.number

      FactoryBot.create(:call_log,
                        session_id: SecureRandom.uuid.remove('-'),
                        caller_phone_number: caller_phone_number,
                        callee_phone_number: callee_phone_number,
                        created_at: creation_date,
                        updated_at: creation_date,
                        duration: rand(60) + 1)

      Rails.logger.info("Created call logs for date #{creation_date}")
    end

    def create_exotel_phone_number_detail(patient, creation_date)
      whitelist_status = ExotelPhoneNumberDetail.whitelist_statuses.to_a.sample.first
      FactoryBot.create(:exotel_phone_number_detail, whitelist_status: whitelist_status,
                        patient_phone_number: patient.phone_numbers.first,
                        created_at: creation_date,
                        updated_at: creation_date)

      Rails.logger.info("Created exotel phone number details for date #{creation_date}")
    end

    def get_traits_for_property(config_hash, property)
      config_hash.dig(property, 'traits')
    end

    def truncate_db
      conn = ActiveRecord::Base.connection
      tables = conn.execute("
      SELECT tablename
      FROM pg_catalog.pg_tables
      WHERE schemaname = 'public' AND
            tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
    ")

      tables.each do |t|
        tablename = t["tablename"]
        conn.execute("TRUNCATE #{tablename} CASCADE")
      end
    end

    def dev_organizations
      [
        {
          name: "IHCI",
          facility_groups: [
            {
              name: "Bathinda and Mansa",
              facilities: [
                { name: "CHC Buccho", district: "Bathinda", state: "Punjab" },
                { name: "CHC Meheraj", district: "Bathinda", state: "Punjab" },
                { name: "District Hospital Bathinda", district: "Bathinda", state: "Punjab" },
                { name: "PHC Joga", district: "Mansa", state: "Punjab" }
              ]
            },
            {
              name: "Gurdaspur",
              facilities: [
                { name: "CHC Kalanaur", district: "Gurdaspur", state: "Punjab" },
                { name: "PHC Bhumbli", district: "Gurdaspur", state: "Punjab" },
                { name: "SDH Batala", district: "Gurdaspur", state: "Punjab" }
              ]
            },
            {
              name: "Bhandara",
              facilities: [
                { name: "CH Bhandara", district: "Bhandara", state: "Maharashtra" },
                { name: "HWC Bagheda", district: "Bhandara", state: "Maharashtra" },
                { name: "HWC Chikhali", district: "Bhandara", state: "Maharashtra" }
              ]
            },
            {
              name: "Hoshiarpur",
              facilities: [
                { name: "CHC Bhol Kalota", district: "Hoshiarpur", state: "Punjab" },
                { name: "PHC Hajipur", district: "Hoshiarpur", state: "Punjab" },
                { name: "SDH Mukerian", district: "Hoshiarpur", state: "Punjab" }
              ]
            },
            {
              name: "Satara",
              facilities: [
                { name: "CHC Satara", district: "Satara", state: "Maharashtra" },
                { name: "PHC Girvi", district: "Satara", state: "Maharashtra" },
                { name: "SDH Indoli", district: "Satara", state: "Maharashtra" }
              ]
            },
          ]
        },
        {
          name: "PATH",
          facility_groups: [
            {
              name: "Amir Singh Facility Group",
              facilities: [
                { name: "Amir Singh", district: "Mumbai", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Anwar Facility Group",
              facilities: [
                { name: "Dr. Anwar", district: "Mumbai", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Abhishek Tripathi",
              facilities: [
                { name: "Dr. Abhishek Tripathi", district: "N Ward", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Shailaja Thorat",
              facilities: [
                { name: "Dr. Shailaja Thorat", district: "Ghatkopar E", state: "Maharashtra" }
              ]
            },
            {
              name: "Dr. Ayazuddin Farooqui",
              facilities: [
                { name: "Dr. Ayazuddin Farooqui", district: "Dharavi", state: "Maharashtra" }
              ]
            }
          ]
        }
      ]
    end

    def create_users(facilities, creation_date, config)
      facilities.each do |f|
        config.dig('users', 'count').times do
          FactoryBot.create(:user, registration_facility: f, created_at: creation_date, updated_at: creation_date)

          create_sync_requested_user(f, creation_date)
          create_sync_denied_user(f, creation_date)
        end
      end

      Rails.logger.info("Created users for date #{creation_date}")
    end

    def create_sync_requested_user(facility, creation_date)
      user = FactoryBot.create(:user,
                               registration_facility: facility,
                               created_at: creation_date,
                               updated_at: creation_date,
                               device_created_at: creation_date,
                               device_updated_at: creation_date)
      user.sync_approval_status = 'requested'
      user.sync_approval_status_reason = ['New Registration', 'Reset PIN'].sample

      user.save
    end

    def create_sync_denied_user(facility, creation_date)
      user = FactoryBot.create(:user,
                               registration_facility: facility,
                               created_at: creation_date,
                               updated_at: creation_date,
                               device_created_at: creation_date,
                               device_updated_at: creation_date)
      user.sync_approval_status = 'denied'
      user.sync_approval_status_reason = 'some random reason'
      user.save
    end


    def create_organizations(creation_date, config)
      dev_organizations.each do |dev_org|
        organization = FactoryBot.create(:organization, name: dev_org[:name],
                                         created_at: creation_date,
                                         updated_at: creation_date)

        create_facility_groups(organization, dev_org[:facility_groups], creation_date, config)
        create_admins(organization)
      end

      Rails.logger.info("Created organizations for date #{creation_date}")
    end

    def create_facility_groups(organization, facility_groups, creation_date, config)
      facility_groups.each do |fac_group|
        facility_group = FactoryBot.create(:facility_group, name: fac_group[:name],
                                           organization: organization,
                                           created_at: creation_date,
                                           updated_at: creation_date)

        facilities = create_and_return_facilities(facility_group, fac_group[:facilities], creation_date)
        create_users(facilities, creation_date, config)
      end

      Rails.logger.info("Created facility groups for date #{creation_date}")
    end

    def create_admins(organization)
      facility_group = organization.facility_groups.first

      FactoryBot.create(:admin, :counsellor, facility_group: facility_group)
      FactoryBot.create(:admin, :analyst, facility_group: facility_group)
      FactoryBot.create(:admin, :supervisor)
      FactoryBot.create(:admin, :organization_owner, organization: organization)

      Rails.logger.info("Created admins for organization #{organization.name}")
    end

    def create_and_return_facilities(facility_group, facilities, creation_date)
      facility_records = []
      facilities.each do |fac|
        facility_records << FactoryBot.create(:facility, facility_group: facility_group,
                                              name: fac[:name],
                                              district: fac[:district],
                                              state: fac[:state],
                                              created_at: creation_date,
                                              updated_at: creation_date)
      end

      Rails.logger.info("Created facilities for facility groyp #{facility_group.name} for date #{creation_date}")
      facility_records
    end
  end
end
