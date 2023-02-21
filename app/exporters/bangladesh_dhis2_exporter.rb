class BangladeshDhis2Exporter
  attr_reader :region, :period

  BUCKETS = (15..75).step(5)

  def self.export
    new.export
  end

  def initialize(region, period)
    unless Flipper.enabled?(:disaggregated_dhis2_export) # TODO aborting from within exporter
      abort("DHIS2 export is not enabled. Use the 'disaggregated_dhis2_export' flag on Flipper to enable it.")
    end

    @region = region
    @period = period

    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
      config.version = ENV.fetch("DHIS2_VERSION")
    end
  end

  def export
    facility_data = []
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      org_unit_id = facility_identifier.identifier

      data.each do |indicator, value|
        data_element_id, disaggregation_id = data_elements_map[indicator].split(".")

        facility_data_element = {
          data_element: data_element_id,
          org_unit: org_unit_id,
          category_option_combo: disaggregation_id,
          period: reporting_period(period),
          value: value
        }

        facility_data << facility_data_element
      end
      pp Dhis2.client.data_value_sets.bulk_create(data_values: facility_data)
    end
  end

  def data
    {
      cumulative_assigned_patients: disaggregated_counts(PatientStates::CumulativeAssignedPatientsQuery.new(region, period)),
      # cumulative_assigned_patients_excluding_recent_registrations: disaggregated_counts(PatientStates::CumulativeAssignedPatientsQuery.new(region, period)),
      controlled_patients: disaggregated_counts(PatientStates::ControlledPatientsQuery.new(region, period)),
      uncontrolled_patients: disaggregated_counts(PatientStates::UncontrolledPatientsQuery.new(region, period))
    }
  end

  def disaggregated_counts(query)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      BUCKETS,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(
        query.call
      )
    ).count
  end

  def data_elements_map
    @data_elements_map ||= CountryConfig.current.fetch(:disaggregated_dhis2_data_elements)
  end

  def reporting_period(month_period)
    if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
      EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_s(:dhis2)
    else
      month_period.to_s(:dhis2)
    end
  end

end
