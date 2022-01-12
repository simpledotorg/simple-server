module Seed
  class PatientSeeder
    include ActiveSupport::Benchmarkable

    def self.call(*args)
      new(*args).call
    end

    attr_reader :config
    attr_reader :facility
    attr_reader :logger
    attr_reader :slug
    attr_reader :user_ids

    def initialize(facility, user_ids:, config:, logger:)
      @facility = facility
      @slug = facility.slug
      @user_ids = user_ids
      @config = config
      @logger = logger
    end

    def call
      benchmark("Seeding records for facility #{slug}") do
        result = {facility: facility.slug}
        benchmark("[#{slug} Seeding patients for a #{facility.facility_size} facility") do
          patients = patients_to_create(facility.facility_size).times.map { |num|
            build_patient
          }
          addresses = patients.map { |patient| patient.address }
          address_result = Address.import(addresses)
          result[:address] = address_result.ids.size
          patient_result = Patient.import(patients, returning: [:id, :recorded_at], recursive: true)
          result[:patient] = patient_result.ids.size
          [result, patient_result.results]
        end
      end
    end

    def build_patient
      start_date = facility.created_at.prev_month # allow for some registrations happening before the facility creation
      recorded_at = Faker::Time.between(from: start_date, to: 1.day.ago)
      user_id = user_ids.sample
      default_attrs = {
        created_at: recorded_at,
        device_created_at: recorded_at,
        device_updated_at: recorded_at,
        patient: nil,
        updated_at: recorded_at
      }
      identifier = FactoryBot.build(:patient_business_identifier,
        default_attrs.merge(metadata: {
          assigning_facility_id: facility.id,
          assigning_user_id: user_id
        }))
      diabetes_trait = weighted_random_diabetes_trait
      medical_history = FactoryBot.build(:medical_history, :hypertension_yes, diabetes_trait, default_attrs.merge(user_id: user_id))
      address = FactoryBot.build(:address, default_attrs.except(:patient))
      phone_number = FactoryBot.build(:patient_phone_number, default_attrs)
      FactoryBot.build(:patient, default_attrs.except(:patient).merge({
        address: address,
        business_identifiers: [identifier],
        medical_history: medical_history,
        phone_numbers: [phone_number],
        status: weighted_random_patient_status,
        registration_user_id: user_id,
        registration_facility: facility
      }))
    end

    def self.weighted_medical_history_traits
      {
        diabetes_yes: 0.06,
        hypertension_yes_diabetes_yes: 0.30,
        hypertension_no: 0.02,
        hypertension_yes: 0.60,
      }
    end

    def self.weighted_diabetes_traits
      {
        diabetes_yes: 0.30,
        diabetes_no: 0.70
      }
    end

    # Return weights of patient statuses that are reasonably close to actual - the vast majority
    # of our patients are active
    def self.weighted_patient_statuses
      {
        active: 0.96,
        dead: 0.02,
        migrated: 0.01,
        unresponsive: 0.005,
        inactive: 0.005
      }
    end

    def weighted_random_diabetes_trait
      return :diabetes_yes if config.test_mode? # make sure we get DM patients in test mode for deterministic specs
      self.class.weighted_diabetes_traits.max_by { |_, weight| rand**(1.0 / weight) }.first
    end

    def weighted_random_patient_status
      self.class.weighted_patient_statuses.max_by { |_, weight| rand**(1.0 / weight) }.first
    end

    def patients_to_create(facility_size)
      max = config.max_patients_to_create.fetch(facility_size.to_sym)
      config.rand_or_max((0..max), scale: true).to_i
    end
  end
end
