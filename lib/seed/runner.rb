require "factory_bot_rails"
require "faker"
require "parallel"
require "ruby-progressbar"

module Seed
  class Runner
    include ActiveSupport::Benchmarkable
    include ConsoleLogger
    SIZES = Facility.facility_sizes

    attr_reader :config
    attr_reader :logger
    attr_reader :start_time
    attr_accessor :counts
    attr_accessor :total_counts

    def self.call(*args)
      new(*args).call
    end

    delegate :scale_factor, :stdout, to: :config
    delegate :distance_of_time_in_words, to: Seed::Helpers

    def initialize(config: Seed::Config.new)
      @counts = {}
      @total_counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      @start_time = Time.current
      announce "Starting #{self.class} with #{config.type} configuration"
    end

    def call
      seed_feature_flags

      result = FacilitySeeder.call(config: config)
      total_counts[:facility] = result&.ids&.size || 0
      UserSeeder.call(config: config)
      seed_drug_stocks

      announce "Starting to seed patient data for #{Facility.count} facilities..."

      progress = create_progress_bar

      results = seed_patients(progress)
      results.each { |hsh| counts[hsh.delete(:facility)] = hsh }
      hsh = sum_facility_totals
      total_counts.merge!(hsh)

      announce <<-EOL
\n⭐️ Seed complete! Created #{Patient.count} patients, #{BloodPressure.count} BPs, #{BloodSugar.count} blood sugars, and #{Appointment.count} appointments across #{Facility.count} facilities in #{Region.district_regions.count} districts.\n
⭐️ Elapsed time #{distance_of_time_in_words(start_time, Time.current, include_seconds: true)} ⭐️\n
      EOL
      [counts, total_counts]
    end

    def feature_flags_enabled_by_default
      [
        :drug_stocks,
        :follow_ups_v2,
        :notifications,
        (:auto_approve_users if SimpleServer.env.android_review?),
        (:fixed_otp if SimpleServer.env.android_review?)
      ].compact
    end

    def seed_feature_flags
      feature_flags_enabled_by_default.each { |flag| Flipper.enable(flag) }
    end

    def seed_patients(progress)
      results = []
      Facility.find_in_batches(batch_size: 100) do |facilities|
        options = parallel_options(progress)
        batch_result = Parallel.map(facilities, options) { |facility|
          registration_user_ids = facility.users.pluck(:id)
          raise "No facility users found to use for registration" if registration_user_ids.blank?

          result, patient_info = PatientSeeder.call(facility, user_ids: registration_user_ids, config: config, logger: logger)
          bp_result = BloodPressureSeeder.call(config: config, facility: facility, user_ids: registration_user_ids)
          result.merge!(bp_result) { |key, count1, count2| count1 + count2 }
          blood_sugar_result = BloodSugarSeeder.call(config: config, facility: facility, user_ids: registration_user_ids)
          result.merge!(blood_sugar_result) { |key, count1, count2| count1 + count2 }
          appt_result = create_appts(patient_info, facility: facility, user_ids: registration_user_ids)
          result[:appointment] = appt_result.ids.size
          result
        }
        results.concat batch_result
      end
      results
    end

    def seed_drug_stocks
      Facility.all.each do |facility|
        user = facility.users.first
        facility.protocol.protocol_drugs.where(stock_tracked: true).each do |protocol_drug|
          FactoryBot.create(:drug_stock, facility: facility, user: user, protocol_drug: protocol_drug)
        end
      end
    end

    def parallel_options(progress)
      parallel_options = {
        finish: lambda do |facility, i, result|
          progress.log("[#{facility.slug}, #{facility.facility_size}] counts: #{result.except(:facility)}")
          progress.increment
        end
      }
      parallel_options[:in_processes] = 0 if Rails.env.test?
      parallel_options
    end

    def sum_facility_totals
      counts.each_with_object(Hash.new(0)) { |(_slug, counts), hsh| counts.each { |type, count| hsh[type] += count } }
    end

    def create_progress_bar
      ProgressBar.create(
        format: "%t |%E | %b\u{15E7}%i %p%% | %a",
        remainder_mark: "\u{FF65}",
        title: "Seeding Facilities",
        total: Facility.count
      )
    end

    def create_appts(patient_info, facility:, user_ids:)
      attrs = patient_info.each_with_object([]) { |(patient_id, recorded_at), attrs|
        number_appointments = config.rand_or_max(0..1) # some patients dont get appointments
        next if number_appointments == 0
        scheduled_date = Faker::Time.between(from: Time.current, to: 45.days.from_now)
        created_at = Faker::Time.between(from: 4.months.ago, to: 1.day.ago)
        user_id = user_ids.sample
        hsh = {
          creation_facility_id: facility.id,
          facility_id: facility.id,
          patient_id: patient_id,
          scheduled_date: scheduled_date,
          created_at: created_at,
          updated_at: created_at,
          user_id: user_id
        }
        attrs << FactoryBot.attributes_for(:appointment, hsh)
      }
      Appointment.import(attrs)
    end
  end
end
