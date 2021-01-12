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
    attr_reader :user

    def initialize(facility, user, config:, logger:)
      @config = config
      @logger = logger
      @facility = facility
      @slug = facility.slug
      @user = user
    end

    def call
      benchmark("Seeding records for facility #{slug}") do
        result = {facility: facility.slug}
        # Set a "birth date" for the Facility that patient records will be based from
        facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
        benchmark("[#{slug} Seeding patients for a #{facility.facility_size} facility") do
          patients = patients_to_create(facility.facility_size).times.map { |num|
            build_patient(user, oldest_registration: facility_birth_date)
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

    def build_patient(user, oldest_registration:)
      recorded_at = Faker::Time.between(from: oldest_registration, to: 1.day.ago)
      identifier = FactoryBot.build(:patient_business_identifier,
        created_at: recorded_at,
        device_created_at: recorded_at,
        device_updated_at: recorded_at,
        patient: nil,
        updated_at: recorded_at,
        metadata: {
          assigning_facility_id: facility.id,
          assigning_user_id: user.id
        })
      medical_history = FactoryBot.build(:medical_history,
        created_at: recorded_at,
        device_created_at: recorded_at,
        device_updated_at: recorded_at,
        patient: nil,
        updated_at: recorded_at,
        user: user)
      address = FactoryBot.build(:address,
        created_at: recorded_at,
        device_created_at: recorded_at,
        device_updated_at: recorded_at,
        updated_at: recorded_at)
      FactoryBot.build(:patient,
        address: address,
        assigned_facility: user.facility,
        created_at: recorded_at,
        recorded_at: recorded_at,
        business_identifiers: [identifier],
        medical_history: medical_history,
        status: patient_status,
        registration_user: user,
        registration_facility: user.facility,
        updated_at: recorded_at)
    end

    def self.status_index
      @status_lookup ||= Patient::STATUSES.each_with_index.to_h
    end

    # Return weights of patient statuses that are reasonably close to actual - the vast majority
    # of our patients are active
    def self.status_weights
      {
        status_index[:active] => 0.96,
        status_index[:dead] => 0.02,
        status_index[:migrated] => 0.01,
        status_index[:unresponsive] => 0.005,
        status_index[:inactive] => 0.005
      }
    end

    def patient_status
      self.class.status_weights.max_by { |_, weight| rand**(1.0 / weight) }.first
    end

    def patients_to_create(facility_size)
      max = config.max_patients_to_create.fetch(facility_size.to_sym)
      config.rand_or_max((0..max), scale: true).to_i
    end
  end
end
