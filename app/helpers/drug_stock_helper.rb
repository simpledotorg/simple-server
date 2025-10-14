module DrugStockHelper
  def drug_stock_region_label(region)
    if region.district_region?
      "#{region.localized_region_type.capitalize} warehouse"
    else
      region.localized_region_type.capitalize
    end
  end

  def filter_params
    params[:zone].present? || params[:size].present?
  end

  def patient_count_for(report)
    if filter_params
      report[:facilities_total_patient_count].to_i
    else
      report[:district_patient_count].to_i
    end
  end

  def drug_stock_for(report, drug)
    if filter_params
      report[:drugs_in_stock_by_facility_id]
        .select { |(_, code), _| code == drug.rxnorm_code }
        .values
        .sum
    else
      report[:total_drugs_in_stock].dig(drug.rxnorm_code).to_i
    end
  end

  def aggregate_state_totals(districts, drugs_by_category, state = nil)
    totals = Hash.new(0)
    patient_days = Hash.new(0)
    patient_count = 0

    districts&.each do |_, data|
      report = data&.[](:report)
      next unless report

      patient_count += patient_count_for(report)

      drugs_by_category&.each do |_, drugs|
        drugs&.each do |drug|
          code = drug&.rxnorm_code&.to_s
          totals[code] += drug_stock_for(report, drug) if code
        end
      end
    end

    patient_days_report = {}

    drugs_by_category&.each do |drug_category, drugs|
      state_coeffs = (state && Reports::DrugStockCalculation.new(
        state: state,
        protocol_drugs: drugs,
        drug_category: drug_category,
        current_drug_stocks: districts&.map { |_, d| d&.[](:report)&.[](:drugs) }&.flatten || [],
        patient_count: patient_count
      ).patient_days_coefficients(state)) || {}

      load_coefficient = state_coeffs&.[]("load_coefficient") || 1
      new_patient_coefficient = state_coeffs&.dig("drug_categories", drug_category.to_s, "new_patient_coefficient") || 1

      adjusted_stock_sum = drugs&.sum do |drug|
        code = drug&.rxnorm_code&.to_s
        coeff = state_coeffs&.dig("drug_categories", drug_category.to_s, code) || 1
        totals[code].to_f * coeff
      end || 0

      patient_days[drug_category] = if patient_count.positive?
        (adjusted_stock_sum / (patient_count * load_coefficient * new_patient_coefficient)).to_i
      else
        0
      end

      stocks = drugs&.map do |drug|
        code = drug&.rxnorm_code&.to_s
        {
          protocol_drug: drug,
          in_stock: totals[code].to_i,
          coefficient: state_coeffs&.dig("drug_categories", drug_category.to_s, code) || 1
        }
      end || []

      patient_days_report[drug_category] = {
        stocks_on_hand: stocks,
        patient_count: patient_count,
        load_coefficient: load_coefficient,
        new_patient_coefficient: new_patient_coefficient,
        patient_days: patient_days[drug_category]
      }
    end

    {
      totals: totals,
      patient_days: patient_days,
      patient_count: patient_count,
      patient_days_report: patient_days_report
    }
  end

  def grouped_district_reports(district_reports)
    district_reports.group_by { |district, _| district.state }.sort_by { |state, _| state }
  end

  def state_aggregate(districts, drugs_by_category)
    totals = Hash.new(0)
    base_totals = Hash.new(0)
    patient_count = 0

    districts.each do |_, data|
      report = data[:report]
      patient_count += report[:district_patient_count].to_i

      drugs_by_category.each do |drug_category, drugs|
        (drugs || []).each do |drug|
          consumed = report[:total_drug_consumption]&.dig(drug_category, drug, :consumed)
          totals[drug.id] += consumed.to_i if consumed.present? && consumed != "error"
        end

        base_total = report[:total_drug_consumption]&.dig(drug_category, :base_doses, :total)
        base_totals[drug_category] += base_total.to_i if base_total.present? && base_total != "error"
      end
    end

    {totals: totals, base_totals: base_totals, patient_count: patient_count}
  end

  def accessible_organization_facilities
    if drug_stock_tracking_slug
      Organization.joins(facility_groups: :facilities).where(facilities: {id: @accessible_facilities}).distinct.pluck(:slug).include?(drug_stock_tracking_slug)
    else
      true
    end
  end

  def drug_stock_tracking_slug
    CountryConfig.current[:drug_stock_tracking_organization_slug]
  end

  def accessible_organization_districts
    if drug_stock_tracking_slug
      @districts = FacilityGroup
        .includes(:facilities)
        .joins(:organization)
        .where(
          organization: {slug: "nhf"},
          id: @accessible_facilities.pluck(:facility_group_id).uniq
        )
        .order(:name)
    else
      FacilityGroup.where(id: @accessible_facilities.pluck(:facility_group_id).uniq).order(:name)
    end
  end

  def district_handling(all_districts_params)
    all_districts_params&.dig(:facility_group) == "all-districts" && all_district_overview_feature_enabled? && accessible_organization_facilities
  end

  def facility_group_dropdown_title(facility_group:, overview: false)
    if can_view_all_districts_nav?
      overview && overview&.dig(:facility_group) == "all-districts" ? "All districts" : (facility_group&.name || "Select Districts")
    else
      facility_group&.name
    end
  end

  def aggregate_district_drug_stock(district_reports, first_drugs_by_category)
    all_totals = Hash.new(0)
    all_patient_days = Hash.new(0)
    all_patient_count = 0

    district_reports.each do |_, data|
      report = data[:report]

      all_patient_count += if filter_params
        report[:facilities_total_patient_count].to_i
      else
        report[:district_patient_count].to_i
      end

      first_drugs_by_category.each do |drug_category, drugs|
        drugs.each do |drug|
          if filter_params
            sum = report[:drugs_in_stock_by_facility_id]
              .select { |(_, code), _| code == drug.rxnorm_code }
              .values
              .sum
            all_totals[drug.rxnorm_code] += sum
          elsif report[:total_drugs_in_stock].dig(drug.rxnorm_code)
            all_totals[drug.rxnorm_code] += report[:total_drugs_in_stock].dig(drug.rxnorm_code).to_i
          end
        end

        if report.dig(:total_patient_days, drug_category, :patient_days)
          all_patient_days[drug_category] += report.dig(:total_patient_days, drug_category, :patient_days).to_i
        end
      end
    end

    {totals: all_totals, patient_days: all_patient_days, patient_count: all_patient_count}
  end

  def aggregate_drug_consumption(district_reports, drugs_by_category)
    all_totals = Hash.new(0)
    all_base_totals = Hash.new(0)
    all_patient_count = 0

    district_reports&.each do |_, data|
      report = data[:report]
      all_patient_count += report[:district_patient_count].to_i

      drugs_by_category.each do |drug_category, drugs|
        (drugs || []).each do |drug|
          consumed = report[:total_drug_consumption]&.dig(drug_category, drug, :consumed)
          all_totals[drug.id] += consumed.to_i if consumed.present? && consumed != "error"
        end

        total_base = report[:total_drug_consumption]&.dig(drug_category, :base_doses, :total)
        all_base_totals[drug_category] += total_base.to_i if total_base.present? && total_base != "error"
      end
    end

    {totals: all_totals, base_totals: all_base_totals, patient_count: all_patient_count}
  end
end
