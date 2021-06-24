class DrugStocksQuery
  include Memery

  CACHE_VERSION = 1

  def initialize(facilities:, for_end_of_month:)
    @facilities = facilities
    @for_end_of_month = for_end_of_month
    # assuming that all facilities on the page have the same protocol
    @protocol = @facilities.first.protocol
    @state = @facilities.first.state
    @latest_drug_stocks = DrugStock.latest_for_facilities(@facilities, @for_end_of_month)
  end

  attr_reader :for_end_of_month

  def drug_stocks_report
    Rails.cache.fetch(drug_stocks_cache_key,
      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
      force: RequestStore.store[:bust_cache]) do
      {total_patients: total_patients,
       all_patient_days: all_patient_days,
       all_drugs_in_stock: all_drugs_in_stock,
       patient_counts_by_facility_id: patient_counts_by_facility_id,
       patient_days_by_facility_id: patient_days_by_facility_id,
       drugs_in_stock_by_facility_id: drugs_in_stock_by_facility_id,
       last_updated_at: Time.now}
    end
  end

  def drug_consumption_report
    Rails.cache.fetch(drug_consumption_cache_key,
      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
      force: RequestStore.store[:bust_cache]) do
      {all: drug_consumption_totals,
       facilities: drug_consumption_report_for_facilities,
       last_updated_at: Time.now}
    end
  end

  memoize def drugs
    @protocol.protocol_drugs.where(stock_tracked: true)
  end

  memoize def protocol_drugs_by_category
    drugs
      .sort_by(&:sort_key)
      .group_by(&:drug_category)
      .sort_by { |(drug_category, _)| drug_category }
      .to_h
  end

  memoize def drug_categories
    drugs.pluck(:drug_category).uniq
  end

  memoize def patient_counts_by_facility_id
    Patient.where(assigned_facility_id: @facilities).group(:assigned_facility_id).count
  end

  memoize def total_patients
    Patient.where(assigned_facility_id: @facilities).count
  end

  memoize def selected_month_drug_stocks
    DrugStock.latest_for_facilities_cte(@facilities, @for_end_of_month).with_protocol_drug_data
  end

  memoize def previous_month_drug_stocks
    DrugStock.latest_for_facilities_cte(@facilities, end_of_previous_month).with_protocol_drug_data
  end

  def all_drugs_in_stock
    selected_month_drug_stocks.group("protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  def drugs_in_stock_by_facility_id
    selected_month_drug_stocks.group(:facility_id, "protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  def select_drug_stocks(drug_stocks, facility_id, drug_category)
    drug_stocks
      .select { |drug_stock| drug_stock.facility_id == facility_id }
      .select { |drug_stock| drug_stock.protocol_drug.drug_category == drug_category }
  end

  def patient_days_by_facility_id
    @facilities.pluck(:id).product(drug_categories).each_with_object({}) do |(facility_id, drug_category), result|
      result[facility_id] ||= {}
      result[facility_id][drug_category] = category_patient_days(
        drug_category,
        select_drug_stocks(selected_month_drug_stocks, facility_id, drug_category),
        patient_counts_by_facility_id[facility_id] || 0
      )
    end
  end

  def category_patient_days(drug_category, category_drug_stocks, patient_count)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol: @protocol,
      drug_category: drug_category,
      stocks_by_rxnorm_code: stocks_by_rxnorm_code(category_drug_stocks),
      patient_count: patient_count
    ).patient_days
  end

  def all_patient_days
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, result|
      result[drug_category] = Reports::DrugStockCalculation.new(
        state: @state,
        protocol: @protocol,
        drug_category: drug_category,
        stocks_by_rxnorm_code: drug_attribute_sum_by_rxnorm_code(:in_stock),
        patient_count: total_patients
      ).patient_days
    end
  end

  memoize def drug_consumption_report_for_facilities
    @facilities.pluck(:id).product(drug_categories).each_with_object({}) do |(facility_id, drug_category), result|
      result[facility_id] ||= {patient_count: patient_counts_by_facility_id[facility_id] || 0}
      result[facility_id][drug_category] =
        drug_consumption_for_category(
          drug_category,
          select_drug_stocks(selected_month_drug_stocks, facility_id, drug_category),
          select_drug_stocks(previous_month_drug_stocks, facility_id, drug_category)
        )
    end
  end

  def drug_consumption_for_category(drug_category, selected_month_drug_stocks, previous_month_drug_stocks)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol: @protocol,
      drug_category: drug_category,
      stocks_by_rxnorm_code: stocks_by_rxnorm_code(selected_month_drug_stocks),
      previous_month_stocks_by_rxnorm_code: stocks_by_rxnorm_code(previous_month_drug_stocks)
    ).consumption
  end

  def drug_consumption_totals
    total_patient_count = total_patients
    report_all = {patient_count: total_patient_count}
    total_previous_month_drug_stocks_by_rxnorm_code = drug_attribute_sum_by_rxnorm_code(:in_stock)
    total_drug_stocks_by_rxnorm_code = drug_attribute_sum_by_rxnorm_code(:in_stock)
    total_drug_received_by_rxnorm_code = drug_attribute_sum_by_rxnorm_code(:received)

    total_drug_stocks_by_rxnorm_code = total_drug_stocks_by_rxnorm_code.deep_merge(total_drug_received_by_rxnorm_code)

    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      consumption = Reports::DrugStockCalculation.new(
        state: @state,
        protocol: @protocol,
        drug_category: drug_category,
        stocks_by_rxnorm_code: total_drug_stocks_by_rxnorm_code,
        previous_month_stocks_by_rxnorm_code: total_previous_month_drug_stocks_by_rxnorm_code
      ).consumption
      next if consumption.nil?
      report_all[drug_category] = consumption
    end
    report_all
  end

  def drug_attribute_sum_by_rxnorm_code(attribute)
    selected_month_drug_stocks
      .group(:protocol_drug)
      .sum(attribute)
      .map { |(protocol_drug, attribute_sum)| [protocol_drug.rxnorm_code, {attribute => attribute_sum}] }
      .to_h
  end

  def stocks_by_rxnorm_code(drug_stocks)
    drug_stocks&.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.rxnorm_code] = drug_stock.as_json.with_indifferent_access
    }
  end

  memoize def end_of_previous_month
    (@for_end_of_month - 1.month).end_of_month
  end

  def drug_stocks_cache_key
    [
      "#{self.class.name}#drug_stocks",
      @facilities.map(&:id).sort,
      @latest_drug_stocks.cache_key,
      @for_end_of_month,
      @protocol.id,
      @state,
      CACHE_VERSION
    ].join("/")
  end

  def drug_consumption_cache_key
    [
      "#{self.class.name}#drug_consumption",
      @facilities.map(&:id).sort,
      @for_end_of_month,
      @protocol.id,
      @state,
      CACHE_VERSION
    ].join("/")
  end
end
