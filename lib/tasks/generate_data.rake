require File.expand_path('spec/utils')
require File.expand_path('db/seeds')

namespace :generate_data do
  DATA_CONCERNS = {
    newly_registered_patients:
      -> (user, sample_range:) {
        FactoryBot
          .build_list(:patient,
                      sample_range,
                      registration_user: user,
                      registration_facility: user.facility)
          .map(&method(:build_patient_payload)) },

    ongoing_bps:
      -> (user, sample_range:, time_range:) {
        user.registered_patients.flat_map do |patient|
          FactoryBot
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
        user.registered_patients.sample([0.15 * user.registered_patients.size, 1].max).flat_map do |patient|
          FactoryBot
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
        user.registered_patients.sample([0.15 * user.registered_patients.size, 1].max).flat_map do |patient|
          next if patient.latest_scheduled_appointment.present?

          appointment = FactoryBot
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
        user.registered_patients.sample([0.15 * user.registered_patients.size, 1].max).flat_map do |patient|
          next if patient.latest_scheduled_appointment.present?

          appointment = FactoryBot
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
        user.registered_patients.sample([0.15 * user.registered_patients.size, 1].max).each do |patient|
          FactoryBot
            .create_list(:call_log,
                         sample_range,
                         result: 'completed',
                         caller_phone_number: user.phone_number,
                         callee_phone_number: patient.latest_phone_number,
                         end_time: time_range)
        end
      }
  }

  def create_resource(data_key, user, range_args = {})
    puts "Creating #{data_key} for #{user.full_name}..."
    DATA_CONCERNS[data_key].call(user, range_args).compact
  end

  def create_api_resource(request_key, data_key, user, range_args = {})
    data = create_resource(data_key, user, range_args)
    api_post("/api/v3/#{request_key}/sync", user, request_key => data) if data.present?
  end

  desc 'Generate seed data; Example: rake "generate_data:seed'
  task :seed => :environment do |_t, _args|
    User.where(role: GENERATED_USER_ROLE).each do |user|
      create_api_resource(:patients,
                          :newly_registered_patients,
                          user,
                          sample_range: rand(30..60))

      create_api_resource(:blood_pressures,
                          :ongoing_bps,
                          user,
                          sample_range: rand(1..3),
                          time_range: Faker::Date.between(1.month.ago, Date.today))

      create_api_resource(:blood_pressures,
                          :retroactive_bps,
                          user,
                          sample_range: rand(1..6),
                          time_range: Faker::Date.between(6.months.ago, 1.month.ago.beginning_of_month))

      create_api_resource(:appointments, :overdue_appointments, user)
      create_api_resource(:appointments, :scheduled_appointments, user)

      create_resource(:completed_phone_calls,
                      user,
                      number_rage: rand(1..3),
                      time_range: Faker::Date.between(3.months.ago, Date.today)))
    end
  end

  HOST = URI.parse(ENV['SIMPLE_SERVER_HOST_PROTOCOL'] + "://" + ENV['SIMPLE_SERVER_HOST']).to_s
  DEFAULT_HEADERS = {'Content-Type' => 'application/json', 'ACCEPT' => 'application/json'}

  def api_post(path, user, data)
    headers =
      DEFAULT_HEADERS.merge('X-USER-ID' => user.id,
                            'X-FACILITY-ID' => user.facility.id)

    output =
      begin
        HTTP
          .auth("Bearer #{user.access_token}")
          .headers(headers)
          .post(URI.parse(HOST + path), :json => data)
      rescue HTTP::Error => e
        puts e
      end

    raise "#{path} failed with status: #{output.status}" unless output.status.ok?
  end
end
