require "factory_bot_rails"
require "faker"
require "parallel"
require "ruby-progressbar"

module Seed
  class Runner
    include ActiveSupport::Benchmarkable
    SIZES = Facility.facility_sizes

    attr_reader :config
    attr_reader :logger
    attr_reader :start_time
    attr_accessor :counts
    attr_accessor :total_counts

    def self.call(*args)
      new(*args).call
    end

    delegate :scale_factor, to: :config
    delegate :distance_of_time_in_words, to: Seed::Helpers

    def initialize(config: Seed::Config.new)
      @counts = {}
      @total_counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      @start_time = Time.current
      puts "Starting #{self.class} with #{config.type} configuration"
    end

    def create_progress_bar
      ProgressBar.create(
        format: "%t |%E | %b\u{15E7}%i %p%% | %a",
        remainder_mark: "\u{FF65}",
        title: "Seeding Facilities",
        total: Facility.count
      )
    end

    def call
      result = FacilitySeeder.call(config: config)
      total_counts[:facility] = result&.ids&.size || 0
      UserSeeder.call(config: config)

      puts "Starting to seed patient data for #{Facility.count} facilities..."

      progress = create_progress_bar

      results = seed_patients(progress)
      results.each { |hsh| counts[hsh.delete(:facility)] = hsh }
      hsh = sum_facility_totals
      total_counts.merge!(hsh)

      msg = "⭐️  Seed complete! Elasped time #{distance_of_time_in_words(start_time, Time.current, include_seconds: true)} ⭐️"
      puts msg
      logger.info msg: msg, counts: counts
      [counts, total_counts]
    end

    def seed_patients(progress)
      parallel_options = {
        finish: lambda do |item, i, result|
          slug, facility_size = item[1], item[2]
          progress.log("Finished facility: [#{slug}, #{facility_size}] counts: #{result}")
          progress.increment
        end
      }
      parallel_options[:in_processes] = 0 if Rails.env.test?

      facility_info = Facility.pluck(:id, :slug, :facility_size)
      Parallel.map(facility_info, parallel_options) do |(facility_id, slug, facility_size)|
        benchmark("Seeding records for facility #{slug}") do
          result = {facility: slug}
          facility = Facility.find(facility_id)
          user = facility.users.find_by!(role: config.seed_generated_active_user_role)
          # Set a "birth date" for the Facility that patient records will be based from
          facility_birth_date = Faker::Time.between(from: 3.years.ago, to: 1.day.ago)
          benchmark("[#{slug} Seeding patients for a #{facility_size} facility") do
            patients = patients_to_create(facility_size).times.map { |num|
              build_patient(user, oldest_registration: facility_birth_date)
            }
            addresses = patients.map { |patient| patient.address }
            address_result = Address.import(addresses)
            result[:address] = address_result.ids.size
            patient_result = Patient.import(patients, recursive: true)
            result[:patient] = patient_result.ids.size
          end
          patient_info = facility.assigned_patients.pluck(:id, :recorded_at)
          bp_result = BloodPressureSeeder.call(config: config, facility: facility, user: user)
          result.merge! bp_result
          appt_result = create_appts(patient_info, user)
          result[:appointment] = appt_result.ids.size
          result
        end
      end
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

    def patients_to_create(facility_size)
      max = config.max_patients_to_create.fetch(facility_size.to_sym)
      config.rand_or_max((0..max), scale: true).to_i
    end

    def sum_facility_totals
      counts.each_with_object(Hash.new(0)) { |(_slug, counts), hsh| counts.each { |type, count| hsh[type] += count } }
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
      Appointment.import(attrs)
    end
  end
end
