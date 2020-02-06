require 'factory_bot_rails'
require 'faker'
require File.expand_path('spec/utils')

class PopulateFakeDataJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low
  sidekiq_throttle threshold: {limit: 20, period: 1.minute}

  FAKE_DATA_USER_ROLE = 'Seeded'
  HOST = URI.parse(ENV['SIMPLE_SERVER_HOST_PROTOCOL'] + "://" + ENV['SIMPLE_SERVER_HOST']).to_s
  DEFAULT_HEADERS = {'Content-Type' => 'application/json', 'ACCEPT' => 'application/json'}
  DATA_CONCERNS = {
    newly_registered_patients:
      -> (user, time_range_fn) {
        build_patient_payload(
          ::FactoryBot
            .build(:patient,
                   recorded_at: time_range_fn.call,
                   registration_user: user,
                   registration_facility: user.facility)
        )
      },

    ongoing_bps:
      -> (user, time_range_fn) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.40).flat_map do |patient|
          build_blood_pressure_payload(
            ::FactoryBot
              .build(:blood_pressure,
                     patient: patient,
                     user: user,
                     recorded_at: time_range_fn.call,
                     facility: user.facility)
          )
        end
      },

    retroactive_bps:
      -> (user, time_range_fn) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.40).flat_map do |patient|
          build_blood_pressure_payload(
            ::FactoryBot
              .build(:blood_pressure,
                     patient: patient,
                     user: user,
                     device_created_at: time_range_fn.call,
                     device_updated_at: time_range_fn.call,
                     facility: user.facility)
          ).except(:recorded_at)
        end
      },

    scheduled_appointments:
      -> (user, _time_range_fn) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.50).flat_map do |patient|
          next if patient.latest_scheduled_appointment.present?

          build_appointment_payload(
            ::FactoryBot
              .build(:appointment,
                     patient: patient,
                     user: user,
                     creation_facility: user.facility,
                     facility: user.facility)
          )
        end
      },

    overdue_appointments:
      -> (user, _time_range_fn) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.50).flat_map do |patient|
          next if patient.latest_scheduled_appointment.present?

          build_appointment_payload(
            ::FactoryBot
              .build(:appointment,
                     :overdue,
                     patient: patient,
                     user: user,
                     creation_facility: user.facility,
                     facility: user.facility)
          )
        end
      },

    completed_phone_calls:
      -> (user, time_range_fn) {
        PopulateFakeDataJob.sample(user.registered_patients, 0.20).each do |patient|
          ::FactoryBot
            .create(:call_log,
                    result: 'completed',
                    caller_phone_number: user.phone_number,
                    callee_phone_number: patient.latest_phone_number,
                    end_time: time_range_fn.call)
        end
      }
  }

  def perform(user_id)
    user = User.find(user_id)

    create_api_resource(:patients,
                        :newly_registered_patients,
                        user,
                        time_range_fn: -> { Faker::Time.between(1.month.ago, Date.today) },
                        sample_range_fn: -> { rand(50..200) })

    create_api_resource(:blood_pressures,
                        :ongoing_bps,
                        user,
                        time_range_fn: -> { Faker::Time.between(1.month.ago, Date.today) },
                        sample_range_fn: -> { rand(1..3) })

    create_api_resource(:blood_pressures,
                        :retroactive_bps,
                        user,
                        time_range_fn: -> { Faker::Time.between(12.months.ago, 1.month.ago.beginning_of_month) },
                        sample_range_fn: -> { rand(2..5) })

    create_api_resource(:appointments, :overdue_appointments, user)
    create_api_resource(:appointments, :scheduled_appointments, user)

    create_resource(:completed_phone_calls,
                    user,
                    time_range_fn: -> { Faker::Time.between(6.months.ago, Date.today) },
                    sample_range_fn: -> { rand(1..10) })
  end

  private

  def create_resource(data_key, user, time_range_fn: -> { Time.now }, sample_range_fn: -> { 1 })
    puts "Creating #{data_key} for #{user.full_name}..."
    (0..sample_range_fn.call).flat_map { DATA_CONCERNS[data_key].call(user, time_range_fn).compact }
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


