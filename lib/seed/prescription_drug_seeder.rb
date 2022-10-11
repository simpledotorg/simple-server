module Seed
  class PrescriptionDrugSeeder
    def self.call(*args)
      new(*args).call
    end

    attr_reader :config
    attr_reader :counts
    attr_reader :facility
    attr_reader :logger
    attr_reader :user_ids
    attr_reader :raw_to_clean_medicines
    delegate :scale_factor, to: :config

    def initialize(config:, facility:, user_ids:)
      @logger = Rails.logger.child(class: self.class.name)
      @counts = {}
      @config = config
      @facility = facility
      @user_ids = user_ids
      @raw_to_clean_medicines = DrugLookup::RawToCleanMedicine.all
      @logger.info "Starting #{self.class} with #{config.type} configuration"
    end

    def encounters
      @facility.encounters
    end

    def prescription_drugs_to_create
      (0...config.max_prescription_drugs_to_create_per_encounter).to_a.sample
    end

    def call
      if config.skip_encounters
        logger.warn { "Skipping seeding prescription drugs, SKIP_ENCOUNTERS is true" }
        return {}
      end

      prescription_drugs = []
      protocol_drugs = if facility.protocol.present?
        facility.protocol.protocol_drugs
      else
        []
      end
      encounters.each_with_index do |encounter, index|
        prescription_drugs_to_create.times do
          prescription_drug_time = encounter.device_created_at + (30...900).to_a.sample.seconds
          sample = raw_to_clean_medicines.sample
          prescription_drug_attributes = {
            created_at: prescription_drug_time,
            device_created_at: prescription_drug_time,
            device_updated_at: prescription_drug_time,
            updated_at: prescription_drug_time,
            is_deleted: index == encounters.size - 1,
            is_protocol_drug: sample.present? && protocol_drugs.map(&:rxnorm_code).include?(sample.rxcui.to_s),
            patient_id: encounter.patient_id,
            facility_id: facility.id,
            user_id: user_ids.sample
          }

          if sample.present?
            prescription_drug_attributes.merge!(
              {
                name: sample.raw_name.humanize,
                rxnorm_code: sample.rxcui,
                dosage: sample.raw_dosage
              }
            )
          end

          prescription_drugs << FactoryBot.attributes_for(:prescription_drug, prescription_drug_attributes)
        end
      end
      result = PrescriptionDrug.import(prescription_drugs, returning: [:id])
      counts[:prescription_drugs] = result.ids.size

      counts
    end
  end
end
