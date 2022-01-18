module Seed
  class BloodPressureSeeder
    def self.call(*args)
      new(*args).call
    end

    attr_reader :config
    attr_reader :counts
    attr_reader :facility
    attr_reader :logger
    attr_reader :user_ids
    delegate :scale_factor, to: :config

    # TODO add some backdated BPs before the facility bday
    def initialize(config:, facility:, user_ids:)
      @logger = Rails.logger.child(class: self.class.name)
      @counts = {}
      @config = config
      @facility = facility
      @user_ids = user_ids
      @logger.info "Starting #{self.class} with #{config.type} configuration"
    end

    def patient_info
      @patient_info ||= @facility.assigned_patients.pluck(:id, :recorded_at)
    end

    PERFORMANCE_WEIGHTS = {
      low: 0.4,
      medium: 0.4,
      high: 0.2
    }

    def performance_rank
      PERFORMANCE_WEIGHTS.max_by { |_, weight| rand**(1.0 / weight) }.first
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

    def controlled_percentage_threshold
      case performance_rank
        when :low then 10
        when :medium then 20
        when :high then 35
      end
    end

    def call
      if config.skip_encounters
        logger.warn { "Skipping seeding blood pressures, SKIP_ENCOUNTERS is true" }
        return {}
      end
      bps = []
      patient_info.each_with_object([]) do |(patient_id, recorded_at)|
        blood_pressures_to_create(performance_rank).times do
          bp_time = Faker::Time.between(from: recorded_at, to: 1.day.ago)
          bp_attributes = {
            created_at: bp_time,
            device_created_at: bp_time,
            device_updated_at: bp_time,
            facility_id: facility.id,
            patient_id: patient_id,
            recorded_at: bp_time,
            updated_at: bp_time,
            user_id: user_ids.sample
          }
          control_trait = rand(100) < controlled_percentage_threshold ? :under_control : :hypertensive
          bps << FactoryBot.attributes_for(:blood_pressure, control_trait, bp_attributes)
        end
      end
      result = BloodPressure.import(bps, returning: [:id, :recorded_at, :patient_id, :user_id])
      counts[:blood_pressure] = result.ids.size

      encounters = []
      result.results.each do |row|
        bp_id, recorded_at, patient_id, user_id = *row
        encounters << {
          blood_pressure_id: bp_id,
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
          observable_id: encounter.delete(:blood_pressure_id),
          observable_type: "BloodPressure",
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
  end
end
