module ReportingPipeline
  class PatientStatesPerMonth < Matview
    belongs_to :patient
    self.table_name = "reporting_patient_states_per_month"
    REGION_ASSOCIATION = {assigned: "assigned", registration: "registration"}.with_indifferent_access
    HTN_CARE_STATES = {under_care: "under_care", lost_to_follow_up: "lost_to_follow_up", dead: "dead"}.with_indifferent_access

    def self.where_regions(region_association, regions)
      Array(regions).inject(nil) do |clauses, region|
        clause = where(region_column_name(region_association, region) => region.slug)
        clauses&.or(clause) || clause
      end
    end

    def self.region_column_name(region_association, region)
      "#{REGION_ASSOCIATION[region_association]}_#{region.region_type}_slug"
    end
  end
end
