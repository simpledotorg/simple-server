class DrugStocksQuery
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
      .order(:name, :dosage)
      .sort_by { |protocol_drug| [protocol_drug.name, protocol_drug.dosage.to_i] }
      .group_by(&:drug_category)
      .sort_by { |(drug_category, _)| drug_category }
      .to_h
  end

  def call
    {all: totals,
     facilities: report_for_facilities}
  end

  def patient_counts
    @patient_counts ||= Patient.where(assigned_facility: @facilities.map(&:id)).group(:assigned_facility).count
  end

  def drug_stocks
    @drug_stocks ||= DrugStock.latest_for_facilities(@facilities, @for_end_of_month).group_by(&:facility_id)
  end

  def report_for_facilities
    @report_for_facilities ||= @facilities.each_with_object({}) { |facility, report|
      facility_patient_count = patient_counts[facility] || 0
      report[facility.id] = drug_stock_for_facility(facility, facility_patient_count, drug_stocks[facility.id])
    }
  end

  def drug_stock_for_facility(facility, patient_count, facility_drug_stocks)
    facility_report = {facility: facility, patient_count: patient_count}
    return facility_report if facility_drug_stocks.nil?

    drug_stocks = facility_drug_stocks.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }
    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      stocks = stocks_by_rxnorm_code(drug_stocks[drug_category])
      patient_days = Reports::PatientDaysCalculation.new(@state, @protocol, drug_category, stocks, patient_count).calculate
      facility_report[drug_category] = patient_days.merge(drug_stocks: drug_stocks_by_drug_id(drug_stocks[drug_category]))
    end
    facility_report
  end

  def drug_stock_totals
    DrugStock.latest_for_facilities(@facilities, @for_end_of_month).group_by(&:protocol_drug).map { |(protocol_drug, drug_stocks)|
      [protocol_drug, drug_stocks&.map(&:in_stock)&.compact.sum]
    }.to_h
  end

  def totals
    total_patient_count = report_for_facilities.map { |(_, facility_report)| facility_report[:patient_count] }.sum
    report_all = {patient_count: total_patient_count}
    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      drug_stock_by_rxnorm_code = drug_stock_totals.map { |(protocol_drug, in_stock)| [protocol_drug.rxnorm_code, in_stock] }.to_h
      drug_stock_by_id = drug_stock_totals.map { |(protocol_drug, in_stock)| [protocol_drug.id, in_stock] }.to_h
      patient_days = Reports::PatientDaysCalculation.new(@state, @protocol, drug_category, drug_stock_by_rxnorm_code, total_patient_count).calculate
      next if patient_days.nil?
      report_all[drug_category] = patient_days.merge(drug_stocks: drug_stock_by_id)
    end
    report_all
  end

  def stocks_by_rxnorm_code(drug_stocks)
    drug_stocks.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.rxnorm_code] = drug_stock.in_stock
    }
  end

  def drug_stocks_by_drug_id(drug_stocks)
    drug_stocks.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end
end
