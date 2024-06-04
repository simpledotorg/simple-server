module Dhis2
  class EthiopiaExporterJob < Dhis2ExporterJob
    AGE_BUCKETS = [18, 30, 40, 70]
    MONTHS_FOR_COHORT_QUERY = 6

    private

    def facility_data_for_period(region, period)
      cohort_registered_patients = PatientStates::Hypertension::RegistrationsForMonthsQuery.new(region, period, MONTHS_FOR_COHORT_QUERY).call
      under_care_patients = PatientStates::Hypertension::RegistrationsUnderCareQuery.new(region, period).call
      {
        htn_enrolled_under_care: {category_option_key: "dhis2_age_gender_category_elements", values: disaggregate_by_gender_age(under_care_patients, AGE_BUCKETS)},
        htn_enrolled_under_care_treatment: {category_option_key: "dhis2_treatment_category_elements", values: segregate_and_format_treatment_data(under_care_patients)},
        htn_by_enrollment_time: {category_option_key: "dhis2_enrollment_time_category_elements", values: segregate_and_format_enrollment_data(PatientStates::Hypertension::CumulativeRegistrationsQuery.new(region, period).call)},
        htn_cohort_registered: {category_option_key: "dhis2_cohort_registered_category_elements", values: format_cohort_registered_data(cohort_registered_patients)},
        htn_cohort_outcome: {category_option_key: "dhis2_cohort_category_elements", values: segregate_and_format_cohort_data(cohort_registered_patients)}
      }
    end

    def data_elements_map
      CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
    end

    def category_element_map(category_element_key)
      CountryConfig.dhis2_data_elements.fetch(category_element_key.to_sym)
    end

    def attribute_option_map_id
      CountryConfig.dhis2_data_elements.fetch(:dhis2_attribute_option)
    end

    def format_facility_period_data(facility_data, facility_identifier, period)
      formatted_facility_data = []
      facility_data.each do |data_element, options|
        attribute_option_id = attribute_option_map_id
        if options[:category_option_key]
          category_element_map(options[:category_option_key]).each do |category_key, id|
            formatted_facility_data << {
              data_element: data_elements_map[data_element],
              org_unit: facility_identifier.identifier,
              category_option_combo: id,
              period: reporting_period(period),
              attribute_option_combo: attribute_option_id,
              value: options[:values][category_key]
            }
          end
        else
          formatted_facility_data << {
            data_element: data_elements_map[data_element],
            org_unit: facility_identifier.identifier,
            period: reporting_period(period),
            attribute_option_combo: attribute_option_id,
            value: options[:value]
          }
        end
      end
      formatted_facility_data
    end

    def segregate_and_format_treatment_data(under_care_patients)
      htn_under_care_patient_count = under_care_patients.count
      lsm_drug_ids = PrescriptionDrug.where('name like ?', '%Life%').pluck(:id)
      htn_under_care_patient_lsm_count = under_care_patients.count { |patient| patient.prescription_drug_id.nil? || lsm_drug_ids.include?(patient.prescription_drug_id) }
      htn_under_care_patient_medication_count = htn_under_care_patient_count - htn_under_care_patient_lsm_count
      {
        "lsm" => htn_under_care_patient_lsm_count,
        "pharma_management" => htn_under_care_patient_medication_count
      }
    end

    def segregate_and_format_enrollment_data(registered_patients)
      registered_patients_count = registered_patients.count
      newly_enrolled_patient_count = registered_patients.count { |patient| patient.months_since_registration == 0 }
      previously_enrolled_patient_count = registered_patients_count - newly_enrolled_patient_count
      {
        "newly_enrolled" => newly_enrolled_patient_count,
        "previously_enrolled" => previously_enrolled_patient_count
      }
    end

    def segregate_and_format_cohort_data(registered_patients)
      controlled_count = registered_patients.count { |patient| patient.htn_care_state == "under_care" && patient.last_bp_state == "controlled" }
      uncontrolled_count = registered_patients.count { |patient| patient.htn_care_state == "under_care" && patient.last_bp_state == "uncontrolled" }
      lost_to_follow_up_count = registered_patients.count { |patient| patient.htn_care_state == "lost_to_follow_up" }
      dead_count = registered_patients.count { |patient| patient.htn_care_state == "dead" }
      transferred_out_count = registered_patients.count { |patient| patient.status == "migrated" }
      {
        "controlled" => controlled_count,
        "uncontrolled" => uncontrolled_count,
        "lost_to_follow_up" => lost_to_follow_up_count,
        "dead" => dead_count,
        "transferred_out" => transferred_out_count
      }
    end

    def format_cohort_registered_data(registered_patients)
      {"default" => registered_patients.count}
    end
  end
end
