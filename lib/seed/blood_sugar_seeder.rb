module Seed
  class BloodSugarSeeder
    def self.call(*args)
      new(*args).call
    end

    attr_reader :config
    attr_reader :counts
    attr_reader :facility
    attr_reader :logger
    attr_reader :user_ids
    delegate :scale_factor, to: :config

    def initialize(config:, facility:, user_ids:)
      @logger = Rails.logger.child(class: self.class.name)
      @counts = {}
      @config = config
      @facility = facility
      @user_ids = user_ids
      @logger.debug "Starting #{self.class} with #{config.type} configuration"
    end

    def blood_sugars_to_create
      config.rand_or_max(0..config.max_blood_sugars_to_create, scale: true).to_i
    end

    def call
      if !facility.diabetes_enabled?
        logger.debug { "Skipping seeding blood sugars, facility #{facility.slug} does not have diabetes enabled" }
        return {}
      end
      blood_sugars = []
      patient_info.each_with_object([]) do |(patient_id, recorded_at)|
        blood_sugars_to_create.times do
          time = Faker::Time.between(from: recorded_at, to: 1.day.ago)
          attrs = {
            created_at: time,
            device_created_at: time,
            device_updated_at: time,
            facility_id: facility.id,
            patient_id: patient_id,
            recorded_at: time,
            updated_at: time,
            user_id: user_ids.sample
          }
          control_trait = :with_hba1c
          blood_sugars << FactoryBot.attributes_for(:blood_sugar, control_trait, attrs)
        end
      end
      result = BloodSugar.import(blood_sugars, returning: [:id, :recorded_at, :patient_id, :user_id])
      counts[:blood_sugar] = result.ids.size

      encounters = []
      result.results.each do |row|
        blood_sugar_id, recorded_at, patient_id, user_id = *row
        encounters << {
          blood_sugar_id: blood_sugar_id,
          created_at: recorded_at,
          device_created_at: recorded_at,
          device_updated_at: recorded_at,
          encountered_on: recorded_at,
          facility_id: facility.id,
          id: SecureRandom.uuid,
          patient_id: patient_id,
          timezone_offset: 0,
          updated_at: recorded_at,
          user_id: user_id
        }
      end
      observations = encounters.each_with_object([]) { |encounter, arry|
        arry << {
          created_at: encounter[:encountered_on],
          encounter_id: encounter[:id],
          observable_id: encounter.delete(:blood_sugar_id),
          observable_type: "BloodSugar",
          updated_at: encounter[:encountered_on],
          user_id: encounter.delete(:user_id)
        }
      }

      encounter_result = Encounter.import(encounters)
      observation_result = Observation.import(observations)
      counts[:encounter] = encounter_result.ids.size
      counts[:observation] = observation_result.ids.size
      counts
    end

    def patient_info
      @patient_info ||= @facility.assigned_patients.pluck(:id, :recorded_at)
    end
  end
end
