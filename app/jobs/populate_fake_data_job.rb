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

  GENERATION_SCRIPT = {
    newly_registered_patients: {
      time_fn: -> { Faker::Time.between(1.month.ago, Date.today) },
      size_fn: -> { rand(50..200) },
      request_key: :patients
    },
    ongoing_bps: {
      time_fn: -> { Faker::Time.between(1.month.ago, Date.today) },
      size_fn: -> { rand(1..3) },
      request_key: :blood_pressures
    },
    retroactive_bps: {
      time_fn: -> { Faker::Time.between(12.months.ago, 1.month.ago.beginning_of_month) },
      size_fn: -> { rand(2..5) },
      request_key: :blood_pressures
    },
    scheduled_appointments: {
      request_key: :appointments
    },
    overdue_appointments: {
      request_key: :appointments
    },
    completed_phone_calls: {
      time_fn: -> { Faker::Time.between(6.months.ago, Date.today) },
      size_fn: -> { rand(1..10) }
    }
  }.freeze

  def perform(user_id)
    @user = User.find(user_id)

    GENERATION_SCRIPT.each do |trait, args|
      create_resources(trait, args)
    end
  end

  private

  def newly_registered_patient(time_fn)
    build_patient_payload(FactoryBot.build(
      :patient,
      recorded_at: time_fn.call,
      registration_user: user,
      registration_facility: user.facility)
    )
  end

  def ongoing_bp(patient, time_fn)
    build_blood_pressure_payload(FactoryBot.build(
      :blood_pressure,
      patient: patient,
      user: user,
      recorded_at: time_fn.call,
      facility: user.facility
    ))
  end

  def retroactive_bp(patient, time_fn)
    build_blood_pressure_payload(FactoryBot.build(
      :blood_pressure,
      patient: patient,
      user: user,
      device_created_at: time_fn.call,
      device_updated_at: time_fn.call,
      facility: user.facility
    )).except(:recorded_at)
  end

  def scheduled_appointment(patient, _time_fn)
    return if patient.latest_scheduled_appointment.present?

    build_appointment_payload(FactoryBot.build(
      :appointment,
      patient: patient,
      user: user,
      creation_facility: user.facility,
      facility: user.facility
    ))
  end

  def overdue_appointment(patient, _time_fn)
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

  def completed_phone_call(patient, time_fn)
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

  def sample(data, factor)
    data.sample([factor * data.size, 1].max)
  end

  def registered_patients
    user.registered_patients
  end

  def sample_patients(percentage)
    sample(registered_patients, percentage)
  end

  def generate(size_fn, args)
    (1...size_fn.call).flat_map { send(**args.values) }
  end

  def generate_for_patient_sample(method_name, percentage:, size_fn:, time_fn:)
    sample_patients(percentage).flat_map do |patient|
      generate(size_fn, method_name: method_name, patient: patient, time_fn: time_fn)
    end
  end

  def create_resources(method_name, request_key:, size_fn:, time_fn:)
    data = generate(size_fn, method_name: method_name, time_fn: time_fn)
    return if request_key.blank?

    data.each_slice(20) do |data_slice|
      api_post("/api/v3/#{request_key}/sync", request_key => data_slice) if data_slice.present?
    end
  end
end
