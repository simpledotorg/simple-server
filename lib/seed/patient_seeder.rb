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
        result = {facility: facility.slug }
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
      address = FactoryBot.build(:address,
        created_at: recorded_at,
        device_created_at: recorded_at,
        device_updated_at: recorded_at,
        updated_at: recorded_at)
      FactoryBot.build(:patient,
        address: address,
        created_at: recorded_at,
        recorded_at: recorded_at,
        registration_user: user,
        registration_facility: user.facility,
        updated_at: recorded_at)
    end

    def patients_to_create(facility_size)
      max = config.max_patients_to_create.fetch(facility_size.to_sym)
      config.rand_or_max((0..max), scale: true).to_i
    end
  end
end
