module OneOff
  module Opensrp
    # OpenSRP::Exporter
    #
    # Base class which acts as an entry point for the rake task.
    class Exporter
      class Config
        attr_reader :report_start, :report_end, :facilities, :time_window, :patients

        def initialize config_file
          data = YAML.load_file(config_file).deep_symbolize_keys.with_indifferent_access
          time_boundaries = data[:time_boundaries]

          @report_start = if has_report_start?(data)
            time_boundaries[:report_start]
          else
            DateTime.parse("2020-01-01")
          end
          @report_end = if has_report_end?(data)
            time_boundaries[:report_end]
          else
            DateTime.now
          end
          @facilities = data[:facilities]
          @time_bound = using_time_boundaries? data
          @time_window = @report_start..@report_end
          @patients = get_patients data
        end

        def time_bound?
          @time_bound || false
        end

        def using_time_boundaries?(config)
          config.has_key? :time_boundaries
        end

        def has_report_start?(config)
          using_time_boundaries?(config) && config[:time_boundaries].has_key?(:report_start)
        end

        def has_report_end?(config)
          using_time_boundaries?(config) && config[:time_boundaries].has_key?(:report_end)
        end

        def get_patients config
          config[:patients] || []
        end
      end

      attr_reader :tally

      def self.export config, output
        new(config, output).call!
      end

      def initialize config_file, output_file, logger: nil
        raise "Config file should be YAML" unless %w[yaml yml].include?(config_file.split(".").last)
        raise "Output file should be JSON" unless output_file.split(".").last == "json"

        if logger.nil?
          initialize_logger
        else
          @logger = logger
        end

        @config = Config.new config_file
        @logger.info "Exporting data using config at #{config_file}"
        @output = output_file
        @resources = []
        @encounters = []
        @tally = Hash.new(0)
      end

      def initialize_logger
        logfile = Rails.root.join("log", "#{Rails.env}.log")
        @logger = ActiveSupport::Logger.new(logfile)
        @logger.extend(ActiveSupport::Logger.broadcast(ActiveSupport::Logger.new($stdout)))
      end

      def call!
        @logger.info "Time Boundaries: [#{@config.report_start}..#{@config.report_end}]"

        patients = select_patients from_facilities: @config.facilities.keys
        patients.each do |patient|
          export_patient_details patient
          export_blood_pressure_details patient
          export_blood_sugar_details patient
          export_prescription_drugs_details patient
          export_appointments_details patient
          export_medical_history_details patient
        end

        @tally[:encounters] += @encounters.size
        @resources << OneOff::Opensrp::EncounterGenerator.new(@encounters).generate

        write_audit_trail patients
      end

      def select_patients from_facilities: []
        raise "No facility selected for export" if from_facilities.empty?

        relation = Patient.where(assigned_facility_id: from_facilities)
        if @config.patients.empty?
          return relation
        else
          return relation.where(id: @config.patients)
        end
      end

      def export_patient_details patient
        return unless @config.time_window.cover?(patient.recorded_at)

        patient_exporter = OneOff::Opensrp::PatientExporter.new(patient, @config.facilities)
        @resources << patient_exporter.export
        @tally[:patients] += 1

        @resources << patient_exporter.export_registration_questionnaire_response
        @tally[:questionnaire_response] += 1

        @encounters << patient_exporter.export_registration_encounter
      end

      def export_blood_pressure_details patient
        blood_pressures = if @config.time_bound?
          patient
            .blood_pressures
            .where(recorded_at: @config.time_window)
            .or(patient
            .blood_pressures
            .where(updated_at: @config.time_window))
        else
          patient.blood_pressures
        end
        @logger.debug "Patient[##{patient.id}] has #{blood_pressures.size} blood pressure readings."
        @tally[:observation] += blood_pressures.size
        blood_pressures.each do |bp|
          # This is technically an FHIR::Observation, with code set to a blood pressure code
          bp_exporter = OneOff::Opensrp::BloodPressureExporter.new(bp, @config.facilities)
          @resources << bp_exporter.export
          @encounters << bp_exporter.export_encounter
        end
      end

      def export_blood_sugar_details patient
        blood_sugars = if @config.time_bound?
          patient
            .blood_sugars
            .where(recorded_at: @config.time_window)
            .or(patient
            .blood_sugars
            .where(updated_at: @config.time_window))
        else
          patient.blood_sugars
        end
        @logger.debug "Patient[##{patient.id}] has #{blood_sugars.size} blood sugar readings."
        @tally[:observation] += blood_sugars.size
        blood_sugars.each do |bs|
          # This is technically an FHIR::Observation, with code set to a blood sugar code
          bs_exporter = OneOff::Opensrp::BloodSugarExporter.new(bs, @config.facilities)
          if patient.medical_history.diabetes_no?
            @resources << bs_exporter.export_no_diabetes_observation
          end
          @resources << bs_exporter.export
          @encounters << bs_exporter.export_encounter
        end
      end

      def export_prescription_drugs_details patient
        prescription_drugs = if @config.time_bound?
          patient
            .prescription_drugs
            .where(created_at: @config.time_window)
            .or(patient
            .prescription_drugs
            .where(updated_at: @config.time_window))
        else
          patient.prescription_drugs
        end
        @logger.debug "Patient[##{patient.id}] has #{prescription_drugs.size} drugs prescribed."
        @tally[:flags] += prescription_drugs.size
        prescription_drugs.each do |drug|
          drug_exporter = OneOff::Opensrp::PrescriptionDrugExporter.new(drug, @config.facilities)
          @resources << drug_exporter.export_dosage_flag
          @encounters << drug_exporter.export_encounter
        end
      end

      def export_appointments_details patient
        appointments = if @config.time_bound?
          patient
            .appointments
            .where(created_at: @config.time_window)
            .or(patient
            .appointments
            .where(updated_at: @config.time_window))
        else
          patient.appointments
        end
        @logger.debug "Patient[##{patient.id}] has #{appointments.size} appointments."
        @tally[:appointments] += appointments.size
        @tally[:tasks] += appointments.includes(:call_results).where.not(call_results: {id: nil}).size
        @tally[:flags] += appointments.includes(:call_results).where.not(call_results: {id: nil}).size
        appointments.each do |appointment|
          appointment_exporter = OneOff::Opensrp::AppointmentExporter.new(appointment, @config.facilities)
          @resources << appointment_exporter.export
          if appointment.call_results.present?
            @resources << appointment_exporter.export_call_outcome_task
            @resources << appointment_exporter.export_call_outcome_flag
          end
          @encounters << appointment_exporter.export_encounter
        end
      end

      def export_medical_history_details patient
        OneOff::Opensrp::MedicalHistoryExporter.new(patient.medical_history, @config.facilities).then do |medical_history_exporter|
          @resources << medical_history_exporter.export
          @encounters << medical_history_exporter.export_encounter
        end
        @tally[:conditions] += 1
      end

      def write_audit_trail patients
        CSV.open("audit_trail.csv", "w") do |csv|
          csv << create_audit_record(@config.facilities, patients.first).keys
          patients.each do |patient|
            csv << create_audit_record(@config.facilities, patient).values
          end
        end
      end

      def create_audit_record(facilities, patient)
        return {} if patient.nil?

        {
          patient_id: patient.id,
          sri_lanka_personal_health_number: patient.business_identifiers.where(identifier_type: "sri_lanka_personal_health_number")&.first&.identifier,
          patient_bp_passport_number: patient.business_identifiers.where(identifier_type: "simple_bp_passport")&.first&.identifier,
          patient_name: patient.full_name,
          patient_gender: patient.gender,
          patient_date_of_birth: patient.date_of_birth || patient.age_updated_at - patient.age.years,
          patient_address: patient.address ? patient.address.street_address : "",
          patient_telephone: patient.phone_numbers.pluck(:number).join(";"),
          patient_facility: facilities[patient.assigned_facility_id][:name],
          patient_preferred_language: "Sinhala",
          patient_active: patient.status_active?,
          patient_deceased: patient.status_dead?,
          condition: ("HTN" if patient.medical_history.hypertension_yes?) || ("DM" if patient.medical_history.diabetes_yes?),
          blood_pressure: patient.latest_blood_pressure&.values_at(:systolic, :diastolic)&.join("/"),
          bmi: nil,
          appointment_date: patient.appointments.order(device_updated_at: :desc).where(status: "scheduled")&.first&.device_updated_at&.to_date&.iso8601,
          medication: patient.prescription_drugs.order(device_updated_at: :desc).where(is_deleted: false)&.first&.values_at(:name, :dosage)&.join(" "),
          glucose_measure: patient.latest_blood_sugar&.blood_sugar_value.then { |bs| "%.2f" % bs if bs },
          glucose_measure_type: patient.latest_blood_sugar&.blood_sugar_type,
          call_outcome: patient.appointments.order(device_updated_at: :desc)&.first&.call_results&.order(device_created_at: :desc)&.first&.result_type
        }
      end

      private

      def read config_file
        YAML.load_file(config_file).deep_symbolize_keys.with_indifferent_access
      end
    end
  end
end
