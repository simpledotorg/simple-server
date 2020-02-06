require 'factory_bot_rails'
require 'faker'
require File.expand_path('spec/utils')

class PopulateFakeDataJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low
  sidekiq_throttle threshold: { limit: 20, period: 1.minute }


  FAKE_DATA_USER_ROLE = 'Seeded'
  HOST = URI.parse(ENV['SIMPLE_SERVER_HOST_PROTOCOL'] + "://" + ENV['SIMPLE_SERVER_HOST']).to_s
  DEFAULT_HEADERS = {'Content-Type' => 'application/json', 'ACCEPT' => 'application/json'}
  DATA_CONCERNS = {
    newly_registered_patients:
      -> (user, sample_range:, time_range:) {
        ::FactoryBot
          .build_list(:patient,
                      sample_range,
                      recorded_at: time_range,
                      registration_user: user,
                      registration_facility: user.facility)
          .map(&method(:build_patient_payload)) },

    ongoing_bps:
      -> (user, sample_range:, time_range:) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.85).flat_map do |patient|
          ::FactoryBot
            .build_list(:blood_pressure,
                        sample_range,
                        patient: patient,
                        user: user,
                        recorded_at: time_range,
                        facility: user.facility)
            .map(&method(:build_blood_pressure_payload))
        end
      },

    retroactive_bps:
      -> (user, sample_range:, time_range:) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.85).flat_map do |patient|
          ::FactoryBot
            .build_list(:blood_pressure,
                        sample_range,
                        patient: patient,
                        user: user,
                        device_created_at: time_range,
                        device_updated_at: time_range,
                        facility: user.facility)
            .map { |bp| build_blood_pressure_payload(bp).except(:recorded_at) }
        end
      },

    scheduled_appointments:
      -> (user, _range_args) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.5).flat_map do |patient|
          next if patient.latest_scheduled_appointment.present?

          appointment = ::FactoryBot
                          .build(:appointment,
                                 patient: patient,
                                 user: user,
                                 creation_facility: user.facility,
                                 facility: user.facility)

          build_appointment_payload(appointment)
        end
      },

    overdue_appointments:
      -> (user, _range_args) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.5).flat_map do |patient|
          next if patient.latest_scheduled_appointment.present?

          appointment = ::FactoryBot
                          .build(:appointment,
                                 :overdue,
                                 patient: patient,
                                 user: user,
                                 creation_facility: user.facility,
                                 facility: user.facility)

          build_appointment_payload(appointment)
        end
      },

    completed_phone_calls:
      -> (user, sample_range:, time_range:) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.4).each do |patient|
          ::FactoryBot
            .create_list(:call_log,
                         sample_range,
                         result: 'completed',
                         caller_phone_number: user.phone_number,
                         callee_phone_number: patient.latest_phone_number,
                         end_time: time_range)
        end
      }
  }

  def perform(user_id)
    user = User.find(user_id)

    create_api_resource(:patients,
                        :newly_registered_patients,
                        user,
                        time_range: Faker::Date.between(1.month.ago, Date.today),
                        sample_range: rand(50..100))

    create_api_resource(:blood_pressures,
                        :ongoing_bps,
                        user,
                        sample_range: rand(1..3),
                        time_range: Faker::Date.between(1.month.ago, Date.today))

    create_api_resource(:blood_pressures,
                        :retroactive_bps,
                        user,
                        sample_range: rand(3..10),
                        time_range: Faker::Date.between(12.months.ago, 1.month.ago.beginning_of_month))

    create_api_resource(:appointments, :overdue_appointments, user)
    create_api_resource(:appointments, :scheduled_appointments, user)

    create_resource(:completed_phone_calls,
                    user,
                    sample_range: rand(1..10),
                    time_range: Faker::Date.between(6.months.ago, Date.today))

  end

  private

  def create_resource(data_key, user, range_args = {})
    puts "Creating #{data_key} for #{user.full_name}..."
    DATA_CONCERNS[data_key].call(user, range_args).compact
  end

  def create_api_resource(request_key, data_key, user, range_args = {})
    data = create_resource(data_key, user, range_args)
    data.each_slice(20) do |data_slice|
      api_post("/api/v3/#{request_key}/sync", user, request_key => data_slice) if data_slice.present?
    end
  end

  def api_post(path, user, data)
    headers = DEFAULT_HEADERS.merge('X-USER-ID' => user.id, 'X-FACILITY-ID' => user.facility.id)
    output = HTTP.auth("Bearer #{user.access_token}").headers(headers).post(URI.parse(HOST + path), json: data)
    unless output.status.ok?
      puts "#{path} failed with status: #{output.status}"
    end
  end

  def self.sample(data, factor)
    data.sample([factor * data.size, 1].max)
  end
end


