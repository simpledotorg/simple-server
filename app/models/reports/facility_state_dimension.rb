module Reports
  # Represents different dimensions of facility state data - i.e. registrations by diagnosis and gender,
  # follow ups by diagnosis and gender, etc.
  # See also FacilityProgressDimension, which is used to generate the permutations of fields to retreive from
  # this matview.
  class FacilityStateDimension < Reports::View
    self.table_name = "reporting_facility_state_dimensions"

    belongs_to :facility

    def self.materialized?
      true
    end

    NON_COUNT_FIELDS = %i[
      block_region_id
      district_region_id
      facility_id
      facility_region_id
      facility_region_slug
      month_date
      state_region_id
    ]

    # Returns the all time totals for a facility as a single FacilityStateDimension record
    def self.totals(facility)
      count_columns = column_names - NON_COUNT_FIELDS.map(&:to_s)
      calculations = count_columns.map { |c| "sum(#{c}) as #{c}" }
      where(facility: facility).select(calculations).to_a.first
    end

    def self.for_region(region_or_source)
      region = region_or_source.region
      where(region_id_field(region) => region.id)
    end

    def self.region_id_field(region)
      "#{region.region_type}_region_id"
    end

    def period
      Period.month(month_date)
    end
  end
end
