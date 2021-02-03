class DrugStocksQuery
  def initialize(facilities:, for_end_of_month:)
    @facilities = facilities
    @for_end_of_month = for_end_of_month
    # assuming that all facilities on the page have the same protocol
    @protocol = @facilities.first.protocol
  end

  def protocol_drugs_by_category
    @drug_categories ||= @protocol.protocol_drugs
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
      patient_days = patient_days_calculations(drug_category, stocks, patient_count)
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
      patient_days = patient_days_calculations(drug_category, drug_stock_by_rxnorm_code, total_patient_count)
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

  def state
    @facilities.first.state
  end

  def patient_days_calculations(drug_category, stocks_by_rxnorm_code, patient_count)
    coefficients = patient_days_coefficients[state]
    stocks_on_hand = stocks_on_hand(coefficients, drug_category, stocks_by_rxnorm_code)
    return nil if stocks_on_hand.nil? || stocks_on_hand.compact.empty?
    new_patient_coefficient = coefficients[:drug_categories][drug_category][:new_patient_coefficient]
    estimated_patients = patient_count * coefficients[:load_factor] * new_patient_coefficient
    {stocks_on_hand: stocks_on_hand,
     patient_count: patient_count,
     load_factor: coefficients[:load_factor],
     new_patient_coefficient: new_patient_coefficient,
     estimated_patients: estimated_patients,
     patient_days: (stocks_on_hand.map { |stock| stock[:stock_on_hand] }.reduce(:+) / estimated_patients).floor}
  rescue
    # either drug stock is nil, or drug is not in formula
    {patient_days: "error"}
  end

  def stocks_on_hand(coefficients, drug_category, stocks_by_rxnorm_code)
    protocol_drugs_by_category[drug_category].map do |protocol_drug|
      rxnorm_code = protocol_drug.rxnorm_code
      coefficient = coefficients[:drug_categories][drug_category][rxnorm_code]
      in_stock = stocks_by_rxnorm_code[rxnorm_code]
      next if in_stock.nil?
      {protocol_drug: protocol_drug,
       in_stock: in_stock,
       coefficient: coefficient,
       stock_on_hand: coefficient * in_stock}
    end
  end

  def patient_days_coefficients
    # move this to config
    {"Karnataka":
        {load_factor: 1,
         drug_categories:
            {"hypertension_ccb":
                {new_patient_coefficient: 1.4,
                 "329528": 1,
                 "329526": 2},
             "hypertension_arb":
                {new_patient_coefficient: 0.37,
                 "316764": 1,
                 "316765": 2,
                 "979467": 1},
             "hypertension_diuretic":
                {new_patient_coefficient: 0.06,
                 "316049": 1,
                 "331132": 1}}},
     "Punjab":
        {load_factor: 1,
         drug_categories:
            {"hypertension_ccb":
                {new_patient_coefficient: 1.4,
                 "329528": 1,
                 "329526": 2},
             "hypertension_arb":
                {new_patient_coefficient: 0.37,
                 "316764": 1,
                 "316765": 2,
                 "979467": 1},
             "hypertension_diuretic":
                {new_patient_coefficient: 0.06,
                 "316049": 1,
                 "331132": 1}}}}.with_indifferent_access
  end
end
