require "factory_bot_rails"
require "faker"

module Seed
  class Runner
    include ActiveSupport::Benchmarkable
    SIZES = Facility.facility_sizes

    attr_reader :config
    attr_reader :logger
    attr_accessor :counts

    def self.call(*args)
      new(*args).call
    end

    delegate :scale_factor, to: :config

    def initialize(config: Seed::Config.new)
      @counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      puts "Starting #{self.class} with #{config.type} configuration"
    end

    def call
      FacilitySeeder.call(config: config)

      active_user_role = ENV["SEED_GENERATED_ACTIVE_USER_ROLE"]
      # user_roles = [ENV["SEED_GENERATED_ACTIVE_USER_ROLE"], ENV["SEED_GENERATED_INACTIVE_USER_ROLE"]]
      Facility.includes(phone_number_authentications: :user).find_each do |facility|
        slug = facility.slug
        benchmark("Seeding records for facility #{slug}") do
          counts[slug] = {patient: 0, blood_pressure: 0}
          user = facility.users.find_by(role: active_user_role)
          # Set a "birth date" for the Facility that patient records will be based from
          facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
          patients_to_create(facility).times do |num|
            create_patient(user, oldest_registration: facility_birth_date)
          end
          patient_info = facility.assigned_patients.pluck(:id, :recorded_at)
          create_bps(patient_info, user, performance_rank)
          create_appts(patient_info, user)
        end
        puts "Seeding complete for facility: #{slug} counts: #{counts[slug]}"
      end
      counts[:total] = sum_facility_totals
      logger.info msg: "Seed complete", counts: counts
      counts
    end

    def self.random_gender
      return Patient::GENDERS.sample if Patient::GENDERS.size == 2
      num = rand(100)
      if num <= 1
        :transgender
      elsif num > 1 && num < 50
        :male
      else
        :female
      end
    end

    def patients_to_create(facility)
      facility_size = facility.facility_size.to_sym
      if config.test_mode?
        config.max_patients_to_create.fetch(facility_size)
      else
        scaled_max_patients = (config.max_patients_to_create.fetch(facility_size) * scale_factor).to_int
        Random.new.rand(0..scaled_max_patients)
      end
    end

    # We adjust the max number of BPs to create by a 'visit perctange' derived from the performance rank.
    # This is to adjust for the fact the lower performing facilities tend to have less visits overall from a patient.
    # We then further adjust it by the overall scaling factor for the entire data set.
    def blood_pressures_to_create(performance_rank)
      if config.test_mode?
        config.max_bps_to_create
      else
        visit_percentage = case performance_rank
          when :low then 0.30
          when :medium then 0.75
          when :high then 1.0
        end
        adjusted_max_bps = (config.max_bps_to_create * visit_percentage * scale_factor).to_int
        Random.new.rand(0..adjusted_max_bps)
      end
    end

    PERFORMANCE_WEIGHTS = {
      low: 0.4,
      medium: 0.4,
      high: 0.2
    }

    def performance_rank
      PERFORMANCE_WEIGHTS.max_by { |_, weight| rand**(1.0 / weight) }.first
    end

    def sum_facility_totals
      counts.each_with_object(Hash.new(0)) { |(_slug, counts), hsh| counts.each { |type, count| hsh[type] += count } }
    end

    # TODO add some backdated BPs before the facility bday
    def create_patient(user, oldest_registration:)
      recorded_at = Faker::Time.between(from: oldest_registration, to: 1.day.ago)
      patient = FactoryBot.create(:patient,
        recorded_at: recorded_at,
        registration_user: user,
        registration_facility: user.facility)
      counts[user.facility.slug][:patient] += 1
      patient
    end

    def create_appts(patient_info, user)
      facility = user.facility
      attrs = patient_info.each_with_object([]) { |(patient_id, recorded_at), attrs|
        scheduled_date = Faker::Time.between(from: Time.current, to: 45.days.from_now)
        hsh = {
          creation_facility_id: facility.id,
          facility_id: facility.id,
          patient_id: patient_id,
          scheduled_date: scheduled_date,
          user_id: user.id
        }
        attrs << FactoryBot.attributes_for(:appointment, hsh)
      }
      appt_result = Appointment.import(attrs)
      counts[facility.slug][:appointment] = appt_result.ids.size
    end

    def create_bps(patient_info, user, performance_rank)
      facility = user.facility
      slug = facility.slug
      controlled_percentage = case performance_rank
        when :low then 10
        when :medium then 20
        when :high then 35
      end
      bps = []
      patient_info.each_with_object([]) do |(patient_id, recorded_at)|
        blood_pressures_to_create(performance_rank).times do
          bp_time = Faker::Time.between(from: recorded_at, to: 1.day.ago)
          bp_attributes = {
            device_created_at: bp_time,
            device_updated_at: bp_time,
            facility_id: facility.id,
            patient_id: patient_id,
            recorded_at: bp_time,
            user_id: user.id
          }
          control_trait = rand(100) < controlled_percentage ? :under_control : :hypertensive
          bps << FactoryBot.attributes_for(:blood_pressure, control_trait, bp_attributes)
        end
      end
      result = BloodPressure.import(bps, returning: [:id, :recorded_at, :patient_id])
      counts[slug][:blood_pressure] = result.ids.size

      encounters = []
      result.results.each do |row|
        bp_id, recorded_at, patient_id = *row
        encounters << {
          blood_pressure_id: bp_id,
          id: SecureRandom.uuid,
          device_created_at: recorded_at,
          device_updated_at: recorded_at,
          encountered_on: recorded_at,
          facility_id: facility.id,
          patient_id: patient_id,
          timezone_offset: 0
        }
      end
      observations = encounters.each_with_object([]) { |encounter, arry|
        arry << {
          created_at: encounter[:encountered_on],
          encounter_id: encounter[:id],
          observable_id: encounter.delete(:blood_pressure_id),
          observable_type: "BloodPressure",
          updated_at: encounter[:encountered_on],
          user_id: user.id
        }
      }

      encounter_result = Encounter.import(encounters)
      observation_result = Observation.import(observations)
      counts[slug][:encounter] = encounter_result.ids.size
      counts[slug][:observation] = observation_result.ids.size
    end
  end
end
