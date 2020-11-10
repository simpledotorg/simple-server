require "factory_bot_rails"
require "faker"

module Seed
  class Runner
    include ActiveSupport::Benchmarkable

    attr_accessor :counts
    attr_reader :logger
    attr_reader :scale_factor

    def initialize(scale_factor: ENV["SEED_FACTOR"]&.to_f || 1.0)
      @counts = {}
      @scale_factor = scale_factor
      @logger = Rails.logger.child(class: self.class.name)
      puts "Starting seed process with scale factor of #{scale_factor}"
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

    SIZES = Facility.facility_sizes
    MAX_BPS_TO_CREATE = 100
    MAX_PATIENTS_TO_CREATE = {
      SIZES[:community] => 200,
      SIZES[:small] => 800,
      SIZES[:medium] => 2000,
      SIZES[:large] => 4000
    }

    def patients_to_create(facility)
      scaled_max_patients = (MAX_PATIENTS_TO_CREATE.fetch(facility.facility_size) * scale_factor).to_int
      Random.new.rand(0..scaled_max_patients)
    end

    # We adjust the max number of BPs to create by a 'visit perctange' derived from the performance rank.
    # This is to adjust for the fact the lower performing facilities tend to have less visits overall from a patient.
    # We then further adjust it by the overall scaling factor for the entire data set.
    def blood_pressures_to_create(performance_rank)
      visit_percentage = case perfromance_rank
        when :low then 0.30
        when :medium then 0.75
        when :high then 1.0
      end
      adjusted_max_bps = (MAX_BPS_TO_CREATE * visit_percentage * scale_factor).to_int
      Random.new.rand(0..adjusted_max_bps)
    end

    PERFORMANCE_WEIGHTS = {
      low: 0.4,
      medium: 0.4,
      high: 0.2
    }

    def performance_rank
      PERFORMANCE_WEIGHTS.max_by { |_, weight| rand ** (1.0 / weight) }.first
    end

    def call
      user_roles = [ENV["SEED_GENERATED_ACTIVE_USER_ROLE"], ENV["SEED_GENERATED_INACTIVE_USER_ROLE"]]
      User.includes(phone_number_authentications: :facility).where(role: user_roles).each do |user|
        facility = user.facility
        slug = facility.slug
        counts[slug] = {patient: 0, blood_pressure: 0}
        benchmark("Seeding records for facility #{slug}") do
          # Set a "birth date" for the Facility that patient records will be based from
          facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
          patients_to_create(facility).times do |num|
            create_patient(user, oldest_registration: facility_birth_date)
          end
          patient_info = facility.assigned_patients.pluck(:id, :recorded_at)
          create_bps(patient_info, user, performance_rank)
        end
        puts "Seeding complete for facility: #{slug} counts: #{counts[slug]}"
      end
      pp @counts
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

    def create_bps(patient_info, user, performance_rank)
      facility = user.facility
      controlled_percentage = case performance_rank
        when :low then 10
        when :medium then 20
        when :high then 35
      end
      bps = []
      appointments = []
      patient_info.each_with_object([]) { |(patient_id, recorded_at)|
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

        scheduled_date = Faker::Time.between(from: 2.weeks.ago, to: 45.days.from_now)
        appointments << FactoryBot.attributes_for(:appointment, facility_id: facility.id, patient_id: patient_id,
                                                                creation_facility_id: facility.id, scheduled_date: scheduled_date)
      }
      result = BloodPressure.import(bps, returning: [:id, :recorded_at, :patient_id])
      counts[user.facility.slug][:blood_pressure] = result.ids.size

      appt_result = Appointment.import(appointments)
      counts[facility.slug][:appointment] = result.ids.size

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

      Encounter.import(encounters)
      Observation.import(observations)

    end
  end
end
