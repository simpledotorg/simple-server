require 'factory_bot_rails'
require 'faker'
require File.expand_path('spec/utils')

class PopulateFakeDataJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low
  sidekiq_throttle threshold: { limit: 20, period: 1.minute }

  attr_reader :user

  FAKE_DATA_USER_ROLE = 'Seeded'.freeze
  HOST = URI.parse("#{ENV['SIMPLE_SERVER_HOST_PROTOCOL']}://#{ENV['SIMPLE_SERVER_HOST']}").to_s
  DEFAULT_HEADERS = { 'Content-Type' => 'application/json', 'ACCEPT' => 'application/json' }.freeze

  TRAITS = {
    newly_registered_patient: {
      time_fn: -> { Faker::Time.between(1.month.ago, Time.now) },
      size_fn: -> { rand(50..200) },
      request_key: :patients
    },
    ongoing_bp: {
      time_fn: -> { Faker::Time.between(1.month.ago, Time.now) },
      size_fn: -> { rand(1..3) },
      request_key: :blood_pressures,
      patient_sample_size: 0.5
    },
    retroactive_bp: {
      time_fn: -> { Faker::Time.between(12.months.ago, 1.month.ago.beginning_of_month) },
      size_fn: -> { rand(2..5) },
      request_key: :blood_pressures,
      patient_sample_size: 0.5
    },
    scheduled_appointment: {
      size_fn: -> { 1 },
      request_key: :appointments,
      patient_sample_size: 0.5
    },
    overdue_appointment: {
      size_fn: -> { 1 },
      request_key: :appointments,
      patient_sample_size: 0.5
    },
    completed_phone_call: {
      time_fn: -> { Faker::Time.between(6.months.ago, Date.today) },
      size_fn: -> { rand(1..10) },
      patient_sample_size: 0.5
    }
  }.freeze

  def perform(user_id)
    @user = User.find(user_id)

    TRAITS.each do |trait, args|
      create_resources(trait, args)
    end
  end

  private

  def newly_registered_patient(time_fn:)
    build_patient_payload(FactoryBot.build(
      :patient,
      recorded_at: time_fn.call,
      registration_user: user,
      registration_facility: user.facility
    ))
  end

  def ongoing_bp(patient:, time_fn:)
    build_blood_pressure_payload(FactoryBot.build(
      :blood_pressure,
      patient: patient,
      user: user,
      recorded_at: time_fn.call,
      facility: user.facility
    ))
  end

  def retroactive_bp(patient:, time_fn:)
    build_blood_pressure_payload(FactoryBot.build(
      :blood_pressure,
      patient: patient,
      user: user,
      device_created_at: time_fn.call,
      device_updated_at: time_fn.call,
      facility: user.facility
    )).except(:recorded_at)
  end

  def scheduled_appointment(patient:)
    return if patient.latest_scheduled_appointment.present?

    build_appointment_payload(FactoryBot.build(
      :appointment,
      patient: patient,
      user: user,
      creation_facility: user.facility,
      facility: user.facility
    ))
  end

  def overdue_appointment(patient:)
    return if patient.latest_scheduled_appointment.present?

    build_appointment_payload(FactoryBot.build(
      :appointment,
      :overdue,
      patient: patient,
      user: user,
      creation_facility: user.facility,
      facility: user.facility
    ))
  end

  def completed_phone_call(patient:, time_fn:)
    FactoryBot.create(
      :call_log,
      result: 'completed',
      caller_phone_number: user.phone_number,
      callee_phone_number: patient.latest_phone_number,
      end_time: time_fn.call
    )
  end

  def api_post(path, data)
    headers = DEFAULT_HEADERS.merge('X-USER-ID' => user.id, 'X-FACILITY-ID' => user.facility.id)
    output = HTTP.auth("Bearer #{user.access_token}").headers(headers).post(URI.parse(HOST + path), json: data)
    puts "#{path} failed with status: #{output.status}" unless output.status.ok?
  end

  def sample_patients(percentage)
    user.registered_patients
        .sample([percentage * user.registered_patients.size, 1].max)
  end

  def generate(trait, args)
    (1..args[:size_fn].call).flat_map { send(trait, args.slice(:patient, :time_fn)) }
  end

  def generate_for_patient_sample(trait, args)
    sample_patients(args[:patient_sample_size]).flat_map do |patient|
      generate(trait, args.merge(patient: patient))
    end
  end

  def create_resources(trait, args)
    "Creating #{trait} for #{user.full_name}..."
    data = args[:patient_sample_size] ? generate_for_patient_sample(trait, args) : generate(trait, args)

    request_key = args[:request_key]
    return if request_key.blank?

    data.each_slice(20) do |data_slice|
      api_post("/api/v3/#{request_key}/sync", request_key => data_slice) if data_slice.present?
    end
  end
end
