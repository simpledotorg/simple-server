class DrugStocksQuery
  CACHE_VERSION = 1

  def initialize(facilities:, for_end_of_month:)
    @facilities = facilities
    @for_end_of_month = for_end_of_month
    # assuming that all facilities on the page have the same protocol
    @protocol = @facilities.first.protocol
    @state = @facilities.first.state
  end

  def protocol_drugs_by_category
    @protocol_drugs_by_category ||= @protocol.protocol_drugs
                                             .where(stock_tracked: true)
                                             .sort_by(&:sort_key)
                                             .group_by(&:drug_category)
                                             .sort_by { |(drug_category, _)| drug_category }
                                             .to_h
  end

  def drug_stocks_report
    Rails.cache.fetch(drug_stocks_cache_key,
                      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
                      force: RequestStore.store[:force_cache]) do
      { all: drug_stock_totals,
        facilities: drug_stock_report_for_facilities,
        last_updated_at: Time.now }
    end
  end

  def drug_consumption_report
    Rails.cache.fetch(drug_consumption_cache_key,
                      expires_in: ENV.fetch("ANALYTICS_DASHBOARD_CACHE_TTL"),
                      force: RequestStore.store[:force_cache]) do
      { all: drug_consumption_totals,
        facilities: drug_consumption_report_for_facilities,
        last_updated_at: Time.now }
    end
  end

  def patient_counts
    @patient_counts ||= Patient.where(assigned_facility_id: @facilities).group(:assigned_facility).count
  end

  def drug_stocks
    @drug_stocks ||= DrugStock.latest_for_facilities(@facilities, @for_end_of_month).group_by(&:facility_id)
  end

  def previous_month_drug_stocks
    @previous_month_drug_stocks ||= DrugStock.latest_for_facilities(@facilities, end_of_previous_month).group_by(&:facility_id)
  end

  def drug_stock_report_for_facilities
    @stock_report_for_facilities ||= @facilities.each_with_object({}) { |facility, report|
      report[facility.id] = drug_stock_for_facility(facility, drug_stocks[facility.id])
    }
  end

  def drug_stock_for_facility(facility, facility_drug_stocks)
    patient_count = patient_counts[facility] || 0
    facility_report = {facility: facility, patient_count: patient_count}
    return facility_report if facility_drug_stocks.nil?

    drug_stocks = facility_drug_stocks.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }
    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      facility_report[drug_category] = drug_stock_for_category(drug_category, drug_stocks, patient_count)
    end
    facility_report
  end

  def drug_stock_for_category(drug_category, drug_stocks, patient_count)
    patient_days = Reports::DrugStockCalculation.new(
      state: @state,
      protocol: @protocol,
      drug_category: drug_category,
      stocks_by_rxnorm_code: stocks_by_rxnorm_code(drug_stocks[drug_category]),
      patient_count: patient_count
    ).patient_days
    return if patient_days.nil?
    patient_days.merge(drug_stocks: drug_stocks_by_drug_id(drug_stocks[drug_category]))
  end

  def drug_consumption_for_category(drug_category, drug_stocks, previous_month_drug_stocks)
    drug_stocks_by_id = drug_stocks_by_drug_id(drug_stocks)
    previous_month_drug_stocks_by_id = drug_stocks_by_drug_id(previous_month_drug_stocks)
    protocol_drugs = protocol_drugs_by_category[drug_category]
    protocol_drugs.each_with_object({}) do |protocol_drug, consumption|
      opening_balance = previous_month_drug_stocks_by_id&.dig(protocol_drug.id)&.in_stock
      received = drug_stocks_by_id&.dig(protocol_drug.id)&.received
      closing_balance = drug_stocks_by_id&.dig(protocol_drug.id)&.in_stock
      consumption[protocol_drug.id] = consumption_calculation(opening_balance, received, closing_balance)
    end
  end

  def drug_consumption_report_for_facilities
    @consumption_report_for_facilities ||= @facilities.each_with_object({}) { |facility, report|
      report[facility.id] = drug_consumption_for_facility(facility, drug_stocks[facility.id], previous_month_drug_stocks[facility.id])
    }
  end

  def drug_consumption_for_facility(facility, facility_drug_stocks, facility_previous_month_drug_stocks)
    patient_count = patient_counts[facility] || 0
    facility_report = { facility: facility, patient_count: patient_count }

    drug_stocks = facility_drug_stocks&.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }
    previous_month_drug_stocks = facility_previous_month_drug_stocks&.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }

    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      facility_report[drug_category] = drug_consumption_for_category(drug_category, drug_stocks&.dig(drug_category), previous_month_drug_stocks&.dig(drug_category))
    end
    facility_report
  end

  def drug_stock_sum(for_end_of_month, attribute)
    drug_stocks = DrugStock.latest_for_facilities(@facilities, for_end_of_month)

    # remove the pluck here
    DrugStock.where({ drug_stocks: { id: drug_stocks.pluck(:id) } }).group(:protocol_drug).sum(attribute)
  end

  def drug_stock_totals
    total_patient_count = patient_counts.values&.sum
    report_all = { patient_count: total_patient_count }
    drug_stock_by_rxnorm_code = drug_stock_sum(@for_end_of_month, :in_stock).map { |(protocol_drug, in_stock)| [protocol_drug.rxnorm_code, in_stock] }.to_h
    drug_stock_by_id = drug_stock_sum(@for_end_of_month, :in_stock).map { |(protocol_drug, in_stock)| [protocol_drug.id, in_stock] }.to_h

    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      patient_days = Reports::DrugStockCalculation.new(
        state: @state,
        protocol: @protocol,
        drug_category: drug_category,
        stocks_by_rxnorm_code: drug_stock_by_rxnorm_code,
        patient_count: total_patient_count
      ).patient_days
      next if patient_days.nil?
      report_all[drug_category] = patient_days.merge(drug_stocks: drug_stock_by_id)
    end
    report_all
  end

  def drug_consumption_totals
    total_patient_count = patient_counts.values&.sum
    report_all = { patient_count: total_patient_count }
    opening_balances = drug_stock_sum(end_of_previous_month, :in_stock)
    received = drug_stock_sum(@for_end_of_month, :received)
    closing_balances = drug_stock_sum(@for_end_of_month, :in_stock)

    protocol_drugs_by_category.each do |(drug_category, protocol_drugs)|
      report_all[drug_category] = {}
      protocol_drugs.each do |protocol_drug|
        report_all[drug_category][protocol_drug] = consumption_calculation(opening_balances[protocol_drug],
                                                                           received[protocol_drug],
                                                                           closing_balances[protocol_drug])
      end
    end
    report_all
  end

  def stocks_by_rxnorm_code(drug_stocks)
    drug_stocks&.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.rxnorm_code] = drug_stock.in_stock
    }
  end

  def drug_stocks_by_drug_id(drug_stocks)
    drug_stocks&.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end

  def end_of_previous_month
    @end_of_previous_month ||= (@for_end_of_month - 1.month).end_of_month
  end

  def drug_stocks_cache_key
    [
      "#{self.class.name}#drug_stocks",
      @facilities.map(&:id).sort,
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

  def consumption_calculation(opening_balance, received, closing_balance)
    return { consumed: nil } if [opening_balance, received, closing_balance].all?(&:nil?)

    {
      opening_balance: opening_balance,
      received: received,
      closing_balance: closing_balance,
      consumed: opening_balance + received - closing_balance
    }

  rescue => e
    # drug is not in formula, or other configuration error
    Sentry.capture_message("Consumption Calculation Error",
                           extra: {
                             protocol: @protocol,
                             opening_balance: opening_balance,
                             received: received,
                             closing_balance: closing_balance,
                             exception: e
                           },
                           tags: { type: "reports" })
    { consumed: "error" }
  end
end
