module PatientReportable
  extend ActiveSupport::Concern
  LTFU_TIME = 12.months

  included do
    has_many :patient_states, class_name: "Reports::PatientState"

    delegate :sanitize_sql, to: ActiveRecord::Base

    scope :with_diabetes, -> { joins(:medical_history).merge(MedicalHistory.diabetes_yes).distinct }
    scope :with_hypertension, -> { joins(:medical_history).merge(MedicalHistory.hypertension_yes).distinct }
    scope :excluding_dead, -> { where.not(status: :dead) }

    scope :ltfu_as_of, ->(time) do
      left_outer_joins(:patient_states)
        .merge(Reports::PatientState.by_month_date(time.beginning_of_month))
        .merge(Reports::PatientState.htn_care_state_lost_to_follow_up)
        .distinct(:patient_id)
    end

    scope :not_ltfu_as_of, ->(time) do
      left_outer_joins(:patient_states)
        .merge(Reports::PatientState.by_month_date(time.beginning_of_month))
        .merge(Reports::PatientState.where.not(htn_care_state: "lost_to_follow_up"))
        .distinct(:patient_id)
    end

    scope :for_reports, ->(exclude_ltfu_as_of: nil) do
      scope = with_hypertension.excluding_dead

      if exclude_ltfu_as_of
        scope.not_ltfu_as_of(exclude_ltfu_as_of)
      else
        scope
      end
    end
  end
end
