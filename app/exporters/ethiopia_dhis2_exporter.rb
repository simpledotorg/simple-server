class EthiopiaDhis2Exporter
  def self.export
    periods = (current_month_period.advance(months: -24)..current_month_period)

    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: periods,
      data_elements_map: CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
    )

    exporter.export do |facility_identifier, period|
      region = facility_identifier.facility.region

      {
        htn_controlled: htn_controlled(region, period),
        htn_cumulative_assigned: htn_cumulative_assigned(region, period),
        htn_cumulative_assigned_adjusted: htn_cumulative_assigned_adjusted(region, period),
        htn_cumulative_registered_patients: htn_cumulative_registered_patients(region, period),
        htn_dead: htn_dead(region, period),
        htn_monthly_registrations: htn_monthly_registrations(region, period),
        htn_ltfu: htn_ltfu(region, period),
        htn_missed_visits: htn_missed_visits(region, period),
        htn_uncontrolled: htn_uncontrolled(region, period)
      }
    end
  end

  def htn_controlled(region, period)
    PatientStates::Hypertension::ControlledPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_cumulative_assigned(region, period)
    PatientStates::Hypertension::CumulativeAssignedPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_cumulative_assigned_adjusted(region, period)
    PatientStates::Hypertension::AdjustedAssignedPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_cumulative_registrations(region, period)
    PatientStates::Hypertension::CumulativeRegistrationsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_dead(region, period)
    PatientStates::Hypertension::DeadPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_monthly_registrations(region, period)
    PatientStates::Hypertension::MonthlyRegistrationsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_ltfu(region, period)
    PatientStates::Hypertension::LostToFollowUpPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_missed_visits(region, period)
    PatientStates::Hypertension::MissedVisitsPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def htn_uncontrolled(region, period)
    PatientStates::Hypertension::UncontrolledPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.current_month_period
    @current_month_period ||= Period.current.previous
  end
end
