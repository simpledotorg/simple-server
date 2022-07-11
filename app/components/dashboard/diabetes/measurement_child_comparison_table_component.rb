class Dashboard::Diabetes::MeasurementChildComparisonTableComponent < ApplicationComponent
  include DashboardHelper

  attr_reader :region
  attr_reader :period
  attr_reader :data
  attr_reader :children_data
  attr_reader :localized_region_type

  def initialize(region:, period:, data:, children_data:, localized_region_type:)
    @region = region
    @period = period
    @data = data
    @children_data = children_data
    @localized_region_type = localized_region_type
  end

  def table_headers
    [{ title: 'RBS &lt;200'.html_safe,
       tooltip: {
         "Numerator" => t("bs_below_200_copy.rbs_ppbs.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'RBS 200-299'.html_safe,
       tooltip: {
         "Numerator" => t("bs_over_200_copy.bs_200_to_299.rbs_ppbs.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'RBS &ge;300'.html_safe,
       tooltip: {
         "Numerator" => t("bs_over_200_copy.bs_over_300.rbs_ppbs.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'FBS &lt;126'.html_safe,
       tooltip: {
         "Numerator" => t("bs_below_200_copy.fasting.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'FBS 126-199'.html_safe,
       tooltip: {
         "Numerator" => t("bs_over_200_copy.bs_200_to_299.fasting.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'FBS &ge;200'.html_safe,
       tooltip: {
         "Numerator" => t("bs_over_200_copy.bs_over_300.fasting.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'HbA1c &lt;7.0'.html_safe,
       tooltip: {
         "Numerator" => t("bs_below_200_copy.hba1c.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'HbA1c 7.0-8.9'.html_safe,
       tooltip: {
         "Numerator" => t("bs_over_200_copy.bs_200_to_299.hba1c.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } },
     { title: 'HbA1c &ge;9.0'.html_safe,
       tooltip: {
         "Numerator" => t("bs_over_200_copy.bs_over_300.hba1c.numerator"),
         "Denominator" => t("bs_measurement_details_copy.assigned_patients_with_bs_measurement", region_name: @region.name)
       } }
    ]
  end

  def row_data(data)
    [:rbs_ppbs, :fasting, :hba1c].flat_map do |blood_sugar_type|
      [:bs_below_200, :bs_200_to_300, :bs_over_300].map do |blood_sugar_risk_state|
        { count: breakdown_count(data, blood_sugar_type, blood_sugar_risk_state),
          rate: breakdown_rate(data, blood_sugar_type, blood_sugar_risk_state),
          patients_with_blood_sugar_measured: data.dig(:diabetes_patients_with_bs_taken, period)
        }
      end
    end
  end

  private

  def breakdown_rate(data, blood_sugar_type, blood_sugar_risk_state)
    return 0 if data.dig(:diabetes_patients_with_bs_taken_breakdown_rates, period) == 0

    if blood_sugar_type == :rbs_ppbs
      return (data.dig(:diabetes_patients_with_bs_taken_breakdown_rates, period, [blood_sugar_risk_state, :random]) || 0) +
        (data.dig(:diabetes_patients_with_bs_taken_breakdown_rates, period, [blood_sugar_risk_state, :post_prandial]) || 0)
    end

    data.dig(:diabetes_patients_with_bs_taken_breakdown_rates, period, [blood_sugar_risk_state, blood_sugar_type]) || 0
  end

  def breakdown_count(data, blood_sugar_type, blood_sugar_risk_state)
    return 0 if data.dig(:diabetes_patients_with_bs_taken_breakdown_counts, period) == 0

    if blood_sugar_type == :rbs_ppbs
      return (data.dig(:diabetes_patients_with_bs_taken_breakdown_counts, period, [blood_sugar_risk_state, :random]) || 0) +
        (data.dig(:diabetes_patients_with_bs_taken_breakdown_counts, period, [blood_sugar_risk_state, :post_prandial]) || 0)
    end

    data.dig(:diabetes_patients_with_bs_taken_breakdown_counts, period, [blood_sugar_risk_state, blood_sugar_type]) || 0
  end
end
