require "factory_bot_rails"
require "faker"
require "parallel"
require "ruby-progressbar"

module Seed
  class Runner
    include ActiveSupport::Benchmarkable
    include ActionView::Helpers::NumberHelper
    include ConsoleLogger
    SIZES = Facility.facility_sizes
    SUMMARY_COUNTS = [:patient, :blood_pressure, :blood_sugar, :appointment, :facility, :facility_group, :prescription_drug]

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
      @bar = "=" * 80
      announce "Starting #{self.class} with #{config.type} configuration\n#{@bar}\n"
    end

    def call
      seed_feature_flags

      result = FacilitySeeder.call(config: config)
      total_counts[:facility] = result&.ids&.size || 0
      UserSeeder.call(config: config)
      seed_drug_stocks

      ProtocolSeeder.call(config: config)
      Seed::DrugLookupTablesSeeder.truncate_and_import

      announce "Starting to seed patient data for #{Facility.count} facilities..."

      progress = create_progress_bar

      results = seed_patients(progress)
      results.each { |hsh| counts[hsh.delete(:facility)] = hsh }
      hsh = sum_facility_totals
      total_counts.merge!(hsh)

      print_summary
      [counts, total_counts]
    end

    def print_summary
      totals = SUMMARY_COUNTS.each_with_object({}) { |model, hsh|
        hsh[model] = number_with_delimiter(model.to_s.classify.constantize.count)
      }
      announce <<~EOL
        \n⭐️ Seed complete! Created #{totals[:patient]} patients, #{totals[:blood_pressure]} BPs, #{totals[:blood_sugar]} blood sugars, #{totals[:prescription_drug]} prescription drugs, and #{totals[:appointment]} appointments across #{totals[:facility]} facilities in #{totals[:facility_group]} districts.\n
        ⭐️ Elapsed time #{distance_of_time_in_words(start_time, Time.current, include_seconds: true)} ⭐️\n
      EOL
    end

    def feature_flags_enabled_by_default
      [
        :dashboard_progress_reports,
        :drug_stocks,
        :follow_ups_v2_progress_tab,
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
          unless config.skip_encounters
            appt_result = create_appts(patient_info, facility: facility, user_ids: registration_user_ids)
            result[:appointment] = appt_result.ids.size
          end
          prescription_drugs_result = PrescriptionDrugSeeder.call(config: config, facility: facility, user_ids: registration_user_ids)
          result.merge!(prescription_drugs_result) { |key, count1, count2| count1 + count2 }

          result
        }
        results.concat batch_result
      end
      results
    end

    def seed_drug_stocks
      ds_attrs = Facility.find_each.with_object([]).each do |facility, attrs|
        logger.info { "Seeding drug stocks for #{facility.id}" }
        user = facility.users.first
        facility.protocol.protocol_drugs.where(stock_tracked: true).each do |protocol_drug|
          attrs << FactoryBot.attributes_for(:drug_stock,
            for_end_of_month: 1.month.ago.end_of_month,
            facility_id: facility.id,
            user_id: user.id,
            protocol_drug_id: protocol_drug.id,
            region_id: facility.region.id)
        end
      end
      DrugStock.import(ds_attrs)
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
