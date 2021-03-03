module Seed
  class PrescriptionDrugSeeder
    def self.call(*args)
      new(*args).call
    end

    attr_reader :config
    attr_reader :counts
    attr_reader :facility
    attr_reader :blood_pressure_info
    attr_reader :user

    def initialize(config:, facility:, user:)
      @logger = Rails.logger.child(class: self.class.name)
      @counts = {}
      @config = config
      @facility = facility
      @user = user
      @blood_pressure_info = @facility.blood_pressures.pluck(:patient_id, :recorded_at)
      @logger.debug "Starting #{self.class} with #{config.type} configuration"
    end

    def call
      drugs = []

      blood_pressure_info.each_with_object([]) do |(patient_id, recorded_at)|
        drugs << {
          id: SecureRandom.uuid,
          name: "Amlodipine",
          dosage: "5 mg",
          rxnorm_code: "329528",
          is_protocol_drug: true,
          is_deleted: false,
          facility_id: facility.id,
          patient_id: patient_id,
          user_id: user.id,
          created_at: recorded_at,
          updated_at: recorded_at,
          device_created_at: recorded_at,
          device_updated_at: recorded_at
        }
      end

      result = PrescriptionDrug.import(drugs, returning: [:id, :device_created_at, :patient_id])
      counts[:prescription_drug] = result.ids.size

      counts
    end
  end
end
