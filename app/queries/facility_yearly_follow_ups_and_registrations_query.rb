class FacilityYearlyFollowUpsAndRegistrationsQuery
  NON_COUNT_FIELDS = %i[
    block_region_id
    district_region_id
    facility_id
    facility_region_id
    facility_region_slug
    month_date
    state_region_id
  ]
  FINANCIAL_YEAR_START_MONTH = 4
  YEAR_START_MONTH = 1

  def initialize(region, current_user)
    @region = region
    @current_user = current_user
    @year_start_month = Flipper.enabled?(:progress_financial_year, @current_user) ? FINANCIAL_YEAR_START_MONTH : YEAR_START_MONTH
  end

  def call
    records = Reports::FacilityMonthlyFollowUpAndRegistration.for_region(@region)
    records_per_period = records.group_by { |facility|
      year(facility.month_date)
    }
    records_per_period.each_with_object([]) do |record_per_period, result|
      period, records = record_per_period
      yearly_data = totals(records)
      yearly_data["year"] = period
      result.push(yearly_data)
    end
  end

  private

  def year(month_date)
    if Flipper.enabled?(:progress_financial_year, @current_user)
      if month_date.month >= @year_start_month
        month_date.year
      elsif month_date.month < @year_start_month
        month_date.year - 1
      end
    else
      month_date.year
    end
  end

  def totals(yearly_data)
    count_columns = Reports::FacilityMonthlyFollowUpAndRegistration.column_names - NON_COUNT_FIELDS.map(&:to_s)
    yearly_data.each_with_object(Hash.new(0)) do |monthly_data, totals|
      count_columns.map do |key|
        new_key = key.gsub("monthly", "yearly")
        totals[new_key] += monthly_data[key]
      end
    end
  end
end
