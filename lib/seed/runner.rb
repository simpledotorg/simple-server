require "factory_bot_rails"
require "faker"
require "parallel"

module Seed
  class Runner
    include ActiveSupport::Benchmarkable
    SIZES = Facility.facility_sizes

    attr_reader :config
    attr_reader :logger
    attr_accessor :counts
    attr_accessor :total_counts

    def self.call(*args)
      new(*args).call
    end

    delegate :scale_factor, to: :config

    def initialize(config: Seed::Config.new)
      @counts = {}
      @total_counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      puts "Starting #{self.class} with #{config.type} configuration"
    end

    def call
      result = FacilitySeeder.call(config: config)
      total_counts[:facility] = result&.ids&.size || 0
      UserSeeder.call(config: config)

      puts "Starting to seed patient data for #{Facility.count} facilities..."

      Facility.includes(phone_number_authentications: :user).find_in_batches(batch_size: 50) do |facilities|
        Parallel.map(facilities, progress: {title: "Seeding facilities", total: Facility.count}) do |facility|
          slug = facility.slug
          benchmark("Seeding records for facility #{slug}") do
            counts[slug] = {patient: 0, blood_pressure: 0}
            user = facility.users.find_by!(role: config.seed_generated_active_user_role)
            # Set a "birth date" for the Facility that patient records will be based from
            facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
            benchmark("[#{slug} Seeding patients for a #{facility.facility_size} facility") do
              patients = patients_to_create(facility).times.map { |num|
                build_patient(user, oldest_registration: facility_birth_date)
              }
              result = Patient.import(patients, recursive: true)
              counts[slug][:patient] = result.ids.size
            end
            patient_info = facility.assigned_patients.pluck(:id, :recorded_at)
            result = BloodPressureSeeder.call(config: config, facility: facility, user: user)
            counts[slug].merge! result
            create_appts(patient_info, user)
          end
          puts "Seeding complete for facility: #{slug} counts: #{counts[slug]}"
          puts
        end
      end
      hsh = sum_facility_totals
      total_counts.merge!(hsh)
      logger.info msg: "Seed complete", counts: counts
      pp total_counts
      counts[:total] = total_counts
      counts
    end

    def self.random_gender
      return Patient::GENDERS.sample if Patient::GENDERS.size == 2
      num = rand(100)
      if num <= 1
        :transgender
      elsif num > 1 && num < 50
        :male
      else
        :female
      end
    end

    def patients_to_create(facility)
      facility_size = facility.facility_size.to_sym
      max = config.max_patients_to_create.fetch(facility_size)
      config.rand_or_max((0..max), scale: true).to_i
    end

    def sum_facility_totals
      counts.each_with_object(Hash.new(0)) { |(_slug, counts), hsh| counts.each { |type, count| hsh[type] += count } }
    end

    def build_patient(user, oldest_registration:)
      recorded_at = Faker::Time.between(from: oldest_registration, to: 1.day.ago)
      FactoryBot.build(:patient,
        address: nil,
        recorded_at: recorded_at,
        registration_user: user,
        registration_facility: user.facility)
    end

    def create_appts(patient_info, user)
      facility = user.facility
      attrs = patient_info.each_with_object([]) { |(patient_id, recorded_at), attrs|
        number_appointments = config.rand_or_max(0..1) # some patients dont get appointments
        next if number_appointments == 0
        scheduled_date = Faker::Time.between(from: Time.current, to: 45.days.from_now)
        hsh = {
          creation_facility_id: facility.id,
          facility_id: facility.id,
          patient_id: patient_id,
          scheduled_date: scheduled_date,
          user_id: user.id
        }
        attrs << FactoryBot.attributes_for(:appointment, hsh)
      }
      appt_result = Appointment.import(attrs)
      counts[facility.slug][:appointment] = appt_result.ids.size
    end
  end
end
