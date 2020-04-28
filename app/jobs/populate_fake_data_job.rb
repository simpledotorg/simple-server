require 'factory_bot_rails'
require 'faker'
require File.expand_path('spec/utils')

class PopulateFakeDataJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low
  sidekiq_throttle threshold: { limit: 5, period: 1.minute }

  attr_reader :user

  USER_ACTIVITY_FACTOR = {
    ENV['ACTIVE_GENERATED_USER_ROLE'] => 1,
    ENV['INACTIVE_GENERATED_USER_ROLE'] => 0.3
  }
  USER_ACTIVITY_FACTOR.default = 0

  FACILITY_SIZE_FACTOR = {
    large: 10,
    medium: 5,
    small: 3,
    community: 1
  }.with_indifferent_access
  FACILITY_SIZE_FACTOR.default = 0

  def patient_traits
    {
      registered_patient: {
        time_fn: -> { Faker::Time.between(from: 9.month.ago, to: Time.now) },
        size_fn: -> { rand(1..2) },
        build_fn: -> (args) {
          build_patient_payload(FactoryBot.build(
            :patient,
            [:hypertension, :diabetes].sample,
            recorded_at: args[:time_fn].call,
            registration_user: user,
            registration_facility: user.facility
          ))
        },
        request_key: :patients,
        api_version: 'v3'
      }
    }
  end

  def traits
    {
      ongoing_bp: {
        time_fn: -> { Faker::Time.between(from: 3.month.ago, to: Time.now) },
        size_fn: -> { rand(1..1) },
        build_fn: -> (args) {
          build_blood_pressure_payload(FactoryBot.build(
            :blood_pressure,
            patient: args[:patient],
            user: user,
            recorded_at: args[:time_fn].call,
            facility: user.facility
          ))
        },
        patient_sample_size: 0.40,
        request_key: :blood_pressures,
        api_version: 'v3',
      },

      retroactive_bp: {
        time_fn: -> { Faker::Time.between(from: 9.months.ago, to: 1.month.ago.beginning_of_month) },
        size_fn: -> { rand(1..2) },
        build_fn: -> (args) {
          now = args[:time_fn].call

          build_blood_pressure_payload(FactoryBot.build(
            :blood_pressure,
            patient: args[:patient],
            user: user,
            device_created_at: now,
            device_updated_at: now,
            facility: user.facility,
          )).except(:recorded_at)
        },
        patient_sample_size: 0.20,
        request_key: :blood_pressures,
        api_version: 'v3',
      },

      ongoing_blood_sugar: {
        time_fn: -> { Faker::Time.between(from: 3.month.ago, to: Time.now) },
        size_fn: -> { rand(1..3) },
        build_fn: -> (args) {
          build_blood_sugar_payload(FactoryBot.build(
            :blood_sugar,
            patient: args[:patient],
            user: user,
            recorded_at: args[:time_fn].call,
            facility: user.facility
          ))
        },
        patient_sample_size: 0.20,
        request_key: :blood_sugars,
        api_version: 'v4'
      },

      retroactive_blood_sugar: {
        time_fn: -> { Faker::Time.between(from: 9.months.ago, to: 1.month.ago.beginning_of_month) },
        size_fn: -> { rand(1..3) },
        build_fn: -> (args) {
          now = args[:time_fn].call

          build_blood_sugar_payload(FactoryBot.build(
            :blood_sugar,
            patient: args[:patient],
            user: user,
            device_created_at: now,
            device_updated_at: now,
            facility: user.facility
          ))
        },
        patient_sample_size: 0.05,
        request_key: :blood_sugars,
        api_version: 'v4'
      },

      scheduled_appointment: {
        size_fn: -> { rand(1..1) },
        build_fn: -> (args) {
          return if patient.latest_scheduled_appointment.present?

          build_appointment_payload(FactoryBot.build(
            :appointment,
            patient: args[:patient],
            user: user,
            creation_facility: user.facility,
            facility: user.facility
          ))
        },
        patient_sample_size: 0.50,
        request_key: :appointments,
        api_version: 'v3'
      },

      overdue_appointment: {
        size_fn: -> { 1 },
        build_fn: -> (args) {
          return if patient.latest_scheduled_appointment.present?

          build_appointment_payload(FactoryBot.build(
            :appointment,
            :overdue,
            patient: args[:patient],
            user: user,
            creation_facility: user.facility,
            facility: user.facility
          ))
        },
        patient_sample_size: 0.50,
        request_key: :appointments,
        api_version: 'v3'
      },

      completed_phone_call: {
        time_fn: -> { Faker::Time.between(from: 9.months.ago, to: Date.today) },
        size_fn: -> { rand(1..1) },
        build_fn: -> (args) {

          FactoryBot.create(
            :call_log,
            result: 'completed',
            caller_phone_number: user.phone_number,
            callee_phone_number: patient.latest_phone_number,
            end_time: args[:time_fn].call
          )
        },
        patient_sample_size: 0.20
      }
    }
  end

  def scale_factor
    USER_ACTIVITY_FACTOR[user.role] * FACILITY_SIZE_FACTOR[user.registration_facility.facility_size]
  end

  def perform(user_id)
    return if ENV['SIMPLE_SERVER_ENV'] == 'production'

    @user = User.find(user_id)

    #
    # register some patients
    #
    patient_trait_args = patient_traits.dig(:registered_patient)
    create_resources(generate(patient_trait_args), :registered_patient, patient_trait_args)

    #
    # generate various traits for the registered patients
    #
    traits.each do |trait_name, trait_args|
      create_resources(generate_traits(trait_args), trait_name, trait_args)
    end
  end

  private

  def create_resources(data, trait_name, trait_args)
    puts "Creating #{trait_name} for #{user.full_name}..."

    request_key = trait_args[:request_key]
    api_version = trait_args[:api_version]
    return if request_key.blank?

    logger.info("Creating #{trait_name} for #{user.full_name}" +
                  "with #{data.size} #{request_key} – facility: #{user.facility.name}")

    data.each_slice(20) do |data_slice|
      api_post("/api/#{api_version}/#{request_key}/sync", request_key => data_slice) if data_slice.present?
    end
  end

  def generate_traits(trait_args)
    user
      .registered_patients
      .sample([trait_args[:patient_sample_size] * user.registered_patients.size, 1].max)
      .flat_map { |patient| generate(trait_args.merge(patient: patient)) }
  end

  def generate(trait_args)
    number_of_records = trait_args[:size_fn].call * scale_factor
    (1..number_of_records).flat_map { trait_args[:build_fn].call(trait_args) }
  end

  def api_post(path, data)
    output = HTTP
               .auth("Bearer #{user.access_token}")
               .headers(api_headers)
               .post(api_url(path), json: data)

    raise HTTP::Error unless output.status.ok?
  end

  def api_headers
    { 'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json',
      'X-USER-ID' => user.id,
      'X-FACILITY-ID' => user.facility.id }
  end

  def api_url(path)
    URI.parse("#{ENV['SIMPLE_SERVER_HOST_PROTOCOL']}://#{ENV['SIMPLE_SERVER_HOST']}/#{path}")
  end
end
