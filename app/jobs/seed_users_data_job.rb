require 'factory_bot_rails'
require 'faker'
require File.expand_path('spec/utils')

class SeedUsersDataJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low
  sidekiq_throttle threshold: {limit: 5, period: 1.minute}

  attr_reader :user

  USER_ACTIVITY_FACTOR = {
    ENV['SEED_GENERATED_ACTIVE_USER_ROLE'] => 1,
    ENV['SEED_GENERATED_INACTIVE_USER_ROLE'] => 0.3
  }
  USER_ACTIVITY_FACTOR.default = 0

  FACILITY_SIZE_FACTOR = {
    large: 10,
    medium: 5,
    small: 3,
    community: 1
  }.with_indifferent_access
  FACILITY_SIZE_FACTOR.default = 0

  SYNC_PAYLOAD_SIZE = 20

  SEED_DATA_AGE = 24.months
  ONGOING_SEED_DATA_AGE = 3.months

  # Add traits here that pertain to creating patients.
  #
  # For every trait, these are the following attributes,
  #
  # time_fn:     this should ideally be a time range, its realized value is passed to build_fn as args[:time]
  # size_fn:     how many records should be created (ideally a range as well)
  # build_fn:    define how to build the API attributes for this trait (typically Factory attributes)
  # request_key: the appropriate sync resource for the trait
  # api_version: the api version of the sync resource to be used
  #
  # Note:
  # If you do not want to create traits through APIs and simply use FactoryBot.create;
  # Just ignore request_key and api_version
  #
  def patient_traits
    @patient_traits ||=
      {
        registered_patient: {
          time_fn: -> { Faker::Time.between(from: SEED_DATA_AGE.ago, to: Time.now) },
          size_fn: -> { rand(20..30) },
          build_fn: -> (args) {
            build_patient_payload(
              FactoryBot.build(:patient,
                recorded_at: args[:time],
                registration_user: user,
                registration_facility: user.facility)
            )
          },
          request_key: :patients,
          api_version: 'v3'
        },

        diagnosis: {
          size_fn: -> { 1 },
          build_fn: -> (args) {
            return if args[:patient].medical_history

            build_medical_history_payload(
              FactoryBot.build(:medical_history,
                [:hypertension_yes, :hypertension_no].sample,
                [:diabetes_yes, :diabetes_no, :diabetes_unknown].sample,
                patient: args[:patient],
                user: user)
            )
          },
          request_key: :medical_histories,
          api_version: 'v3',
          patient_sample_size: 1
        }
      }
  end

  # Add traits here that define a property on patient.
  #
  # The attributes here are a superset of the patient_traits,
  #
  # patient_sample_size: how many patients for the user to apply this trait to (factor between 0 to 1)
  #
  def per_patient_traits
    @per_patient_traits ||=
      {
        ongoing_bp: {
          time_fn: -> { Faker::Time.between(from: ONGOING_SEED_DATA_AGE.ago, to: Time.now) },
          size_fn: -> { rand(1..3) },
          build_fn: -> (args) {
            build_blood_pressure_payload(
              FactoryBot.build(:blood_pressure,
                patient: args[:patient],
                user: user,
                recorded_at: args[:time],
                facility: user.facility)
            )
          },
          patient_sample_size: 0.40,
          request_key: :blood_pressures,
          api_version: 'v3',
        },

        retroactive_bp: {
          time_fn: -> { Faker::Time.between(from: SEED_DATA_AGE.ago, to: 1.month.ago.beginning_of_month) },
          size_fn: -> { rand(1..2) },
          build_fn: -> (args) {
            build_blood_pressure_payload(
              FactoryBot.build(:blood_pressure,
                patient: args[:patient],
                user: user,
                device_created_at: args[:time],
                device_updated_at: args[:time],
                facility: user.facility)
            ).except(:recorded_at)
          },
          patient_sample_size: 0.20,
          request_key: :blood_pressures,
          api_version: 'v3',
        },

        ongoing_blood_sugar: {
          time_fn: -> { Faker::Time.between(from: ONGOING_SEED_DATA_AGE.ago, to: Time.now) },
          size_fn: -> { rand(1..3) },
          build_fn: -> (args) {
            build_blood_sugar_payload(
              FactoryBot.build(:blood_sugar,
                :with_hba1c,
                patient: args[:patient],
                user: user,
                recorded_at: args[:time],
                facility: user.facility)
            )
          },
          patient_sample_size: 0.20,
          request_key: :blood_sugars,
          api_version: 'v4'
        },

        retroactive_blood_sugar: {
          time_fn: -> { Faker::Time.between(from: SEED_DATA_AGE.ago, to: 1.month.ago.beginning_of_month) },
          size_fn: -> { rand(1..3) },
          build_fn: -> (args) {
            build_blood_sugar_payload(
              FactoryBot.build(:blood_sugar,
                :with_hba1c,
                patient: args[:patient],
                user: user,
                device_created_at: args[:time],
                device_updated_at: args[:time],
                facility: user.facility)
            )
          },
          patient_sample_size: 0.05,
          request_key: :blood_sugars,
          api_version: 'v4'
        },

        scheduled_appointment: {
          size_fn: -> { 1 },
          build_fn: -> (args) {
            return if args[:patient].latest_scheduled_appointment.present?

            build_appointment_payload(
              FactoryBot.build(:appointment,
                patient: args[:patient],
                user: user,
                creation_facility: user.facility,
                facility: user.facility)
            )
          },
          patient_sample_size: 0.50,
          request_key: :appointments,
          api_version: 'v3'
        },

        overdue_appointment: {
          size_fn: -> { rand(1..2) },
          build_fn: -> (args) {
            return if args[:patient].latest_scheduled_appointment.present?

            build_appointment_payload(
              FactoryBot.build(:appointment,
                :overdue,
                patient: args[:patient],
                user: user,
                creation_facility: user.facility,
                facility: user.facility)
            )
          },
          patient_sample_size: 0.50,
          request_key: :appointments,
          api_version: 'v3'
        },

        completed_phone_call: {
          time_fn: -> { Faker::Time.between(from: SEED_DATA_AGE.ago, to: Date.today) },
          size_fn: -> { rand(1..1) },
          build_fn: -> (args) {
            FactoryBot.create(:call_log,
              result: 'completed',
              caller_phone_number: user.phone_number,
              callee_phone_number: args[:patient].latest_phone_number,
              end_time: args[:time])
          },
          patient_sample_size: 0.20
        }
      }
  end

  class InvalidSeedUsersDataOperation < RuntimeError; end

  def perform(user_id)
    raise InvalidSeedUsersDataOperation,
      "Can't generate seed data in #{ENV['SIMPLE_SERVER_ENV']}!" if ENV['SIMPLE_SERVER_ENV'] == 'production'

    @user = User.find(user_id)

    #
    # register some patients
    #
    patient_trait = patient_traits[:registered_patient]
    registered_patients = trait_record_size(patient_trait).times.flat_map do
      build_trait(patient_trait)
    end
    create_trait(registered_patients, :registered_patient, patient_trait)

    #
    # add their diagnosis
    #
    diagnosis_trait = patient_traits[:diagnosis]
    diagnosis_data = user.registered_patients.flat_map do |patient|
      build_trait(diagnosis_trait, patient: patient)
    end.compact
    create_trait(diagnosis_data, :diagnosis, diagnosis_trait)

    #
    # generate various traits per patient
    #
    per_patient_traits.each do |trait_name, trait|
      create_trait(build_traits_per_patient(trait), trait_name, trait)
    end
  end

  private

  def create_trait(trait_data, trait_name, trait)
    puts "Creating #{trait_name} for #{user.full_name}..."

    request_key = trait[:request_key]
    api_version = trait[:api_version]
    return if request_key.blank?

    logger.info("Creating #{trait_name} for #{user.full_name} " +
      "with #{trait_data.size} #{request_key} – facility: #{user.facility.name}")

    trait_data.each_slice(SYNC_PAYLOAD_SIZE) do |data_slice|
      api_post("/api/#{api_version}/#{request_key}/sync", request_key => data_slice) if data_slice.present?
    end
  end

  def build_traits_per_patient(trait)
    sample_registered_patients(trait)
      .flat_map do |patient|
      number_of_records_per_patient(trait)
        .times
        .map { build_trait(trait, patient: patient) }
        .compact
    end
  end

  def sample_registered_patients(trait)
    registered_patients = user.registered_patients
    sample_size = [trait[:patient_sample_size] * registered_patients.size, 1].max
    registered_patients.sample(sample_size)
  end

  def number_of_records_per_patient(trait)
    (trait_record_size(trait) * traits_scale_factor).to_i
  end

  def build_trait(trait, build_params = {})
    build_params = build_params.merge(time: trait_time(trait))
    trait[:build_fn].call(build_params)
  end

  def trait_record_size(trait)
    trait[:size_fn].call.to_i
  end

  def trait_time(trait)
    trait[:time_fn]&.call
  end

  def traits_scale_factor
    USER_ACTIVITY_FACTOR[user.role] * FACILITY_SIZE_FACTOR[user.registration_facility.facility_size]
  end

  def api_post(path, data)
    output = HTTP
               .auth("Bearer #{user.access_token}")
               .headers(api_headers)
               .post(api_url(path), json: data)

    raise HTTP::Error unless output.status.ok?
  end

  def api_headers
    {'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json',
      'X-USER-ID' => user.id,
      'X-FACILITY-ID' => user.facility.id}
  end

  def api_url(path)
    URI.parse("#{ENV['SIMPLE_SERVER_HOST_PROTOCOL']}://#{ENV['SIMPLE_SERVER_HOST']}/#{path}")
  end
end
