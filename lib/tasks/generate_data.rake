require File.expand_path('spec/utils')

namespace :generate_data do
  DATA = {
    newly_registered_patients:
      -> (user) { FactoryBot
                    .build_list(:patient,
                                rand(30..100),
                                registration_user: user,
                                registration_facility: user.facility)
                    .map(&method(:build_patient_payload)) },

    ongoing_bps:
      -> (user) {
        user.registered_patients.flat_map do |patient|
          FactoryBot
            .build_list(:blood_pressure,
                        rand(1..3),
                        patient: patient,
                        user: user,
                        recorded_at: Faker::Date.between(1.month.ago, Date.today),
                        facility: user.facility)
            .map(&method(:build_blood_pressure_payload))
        end
      },

    retroactive_bps:
      -> (user) {
        user.registered_patients.sample([0.15 * user.registered_patients.size, 1].max).flat_map do |patient|
          FactoryBot
            .build_list(:blood_pressure,
                        rand(1..6),
                        patient: patient,
                        user: user,
                        device_created_at: Faker::Date.between(6.months.ago, 1.month.ago.beginning_of_month),
                        device_updated_at: Faker::Date.between(6.months.ago, 1.month.ago.beginning_of_month),
                        facility: user.facility)
            .map { |bp| build_blood_pressure_payload(bp).except(:recorded_at) }
        end
      },

    scheduled_appointments:
      -> (user) {
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
      -> (user) {
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
      -> (user) {
        user.registered_patients.sample([0.15 * user.registered_patients.size, 1].max).each do |patient|
          FactoryBot
            .create_list(:call_log,
                         rand(1..3),
                         result: 'completed',
                         caller_phone_number: user.phone_number,
                         callee_phone_number: patient.latest_phone_number,
                         end_time: Faker::Date.between(3.months.ago, Date.today))
        end
      }
  }

  def create_resource(request_key, data_key, user)
    puts "Creating #{data_key} for #{user.full_name}..."

    data = DATA[data_key].call(user).compact
    return if data.blank?

    api_post("/api/v3/#{request_key}/sync", user, request_key => data)
  end

  desc 'Generate seed data; Example: rake "generate_data:seed'
  task :seed => :environment do |_t, _args|
    PhoneNumberAuthentication.all.each do |phone_authentication|
      #create_resource(:patients, :newly_registered_patients, phone_authentication.user)
      #create_resource(:blood_pressures, :ongoing_bps, phone_authentication.user)
      #create_resource(:blood_pressures, :retroactive_bps, phone_authentication.user)
      #create_resource(:appointments, :scheduled_appointments, phone_authentication.user)
      #create_resource(:appointments, :overdue_appointments, phone_authentication.user)

      DATA[:completed_phone_calls].call(phone_authentication.user)
    end
  end


  HOST = 'http://localhost:3001'.freeze
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
