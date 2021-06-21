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

  memoize def drugs
    @protocol.protocol_drugs.where(stock_tracked: true)
  end

  memoize def drug_categories
    drugs.pluck(:drug_category).uniq
  end

  memoize def protocol_drugs_by_category
    drugs
      .sort_by(&:sort_key)
      .group_by(&:drug_category)
      .sort_by { |(drug_category, _)| drug_category }
      .to_h
  end

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

  memoize def patient_counts_by_facility_id
    Patient.where(assigned_facility_id: @facilities).group(:assigned_facility_id).count
  end

  memoize def total_patients
    Patient.where(assigned_facility_id: @facilities).count
  end

  memoize def drug_stocks
    DrugStock.latest_for_facilities_cte(@facilities, @for_end_of_month).with_protocol_drug_data
  end

  memoize def previous_month_drug_stocks
    DrugStock.latest_for_facilities(@facilities, end_of_previous_month).group_by(&:facility_id)
  end

  def all_drugs_in_stock
    drug_stocks.group("protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  def drugs_in_stock_by_facility_id
    drug_stocks.group(:facility_id, "protocol_drugs.rxnorm_code").sum(:in_stock)
  end

  def patient_days_by_facility_id
    @facilities.each_with_object({}) { |facility, report|
      facility_drug_stocks = drug_stocks.select { |drug_stock| drug_stock.facility_id == facility.id }
      patient_count = patient_counts_by_facility_id[facility.id] || 0

      report[facility.id] = facility_patient_days(facility_drug_stocks, patient_count)
    }
  end

  def facility_patient_days(facility_drug_stocks, patient_count)
    drug_categories.each_with_object({}) do |drug_category, report|
      category_drug_stocks = facility_drug_stocks.select { |drug_stock| drug_stock.protocol_drug.drug_category == drug_category }

      report[drug_category] = category_patient_days(drug_category, category_drug_stocks, patient_count)
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

  def drug_consumption_for_category(drug_category, selected_month_drug_stocks, previous_month_drug_stocks)
    Reports::DrugStockCalculation.new(
      state: @state,
      protocol: @protocol,
      drug_category: drug_category,
      stocks_by_rxnorm_code: stocks_by_rxnorm_code(selected_month_drug_stocks),
      previous_month_stocks_by_rxnorm_code: stocks_by_rxnorm_code(previous_month_drug_stocks)
    ).consumption
  end

  memoize def drug_consumption_report_for_facilities
    @facilities.each_with_object({}) { |facility, report|
      report[facility.id] = drug_consumption_for_facility(facility, drug_stocks[facility.id], previous_month_drug_stocks[facility.id])
    }
  end

  def drug_consumption_for_facility(facility, facility_drug_stocks, facility_previous_month_drug_stocks)
    patient_count = patient_counts_by_facility[facility] || 0
    facility_report = {facility: facility, patient_count: patient_count}

    drug_stocks = facility_drug_stocks&.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }
    previous_month_drug_stocks = facility_previous_month_drug_stocks&.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }

    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      facility_report[drug_category] = drug_consumption_for_category(drug_category, drug_stocks&.dig(drug_category), previous_month_drug_stocks&.dig(drug_category))
    end
    facility_report
  end

  def drug_attribute_sum_by_rxnorm_code(for_end_of_month, attribute)
    drug_stocks = DrugStock.latest_for_facilities(@facilities, for_end_of_month)

    # remove the pluck here
    DrugStock
      .where({drug_stocks: {id: drug_stocks.pluck(:id)}})
      .group(:protocol_drug)
      .sum(attribute)
      .map { |(protocol_drug, attribute_sum)| [protocol_drug.rxnorm_code, {attribute => attribute_sum}] }
      .to_h
  end

  def all_patient_days
    drug_categories.each_with_object(Hash.new(0)) do |drug_category, report|
      report[drug_category] = Reports::DrugStockCalculation.new(
        state: @state,
        protocol: @protocol,
        drug_category: drug_category,
        stocks_by_rxnorm_code: drug_attribute_sum_by_rxnorm_code(@for_end_of_month, :in_stock),
        patient_count: total_patients
      ).patient_days
    end
  end

  def drug_consumption_totals
    total_patient_count = total_patients
    report_all = {patient_count: total_patient_count}
    total_previous_month_drug_stocks_by_rxnorm_code = drug_attribute_sum_by_rxnorm_code(end_of_previous_month, :in_stock)
    total_drug_stocks_by_rxnorm_code = drug_attribute_sum_by_rxnorm_code(@for_end_of_month, :in_stock)
    total_drug_received_by_rxnorm_code = drug_attribute_sum_by_rxnorm_code(@for_end_of_month, :received)

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
