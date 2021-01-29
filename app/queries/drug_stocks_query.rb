class DrugStocksQuery
  def initialize(facilities:, for_end_of_month:)
    @facilities = facilities
    @for_end_of_month = for_end_of_month
    # assuming that all facilities on the page have the same protocol
    @protocol = @facilities.first.protocol
  end

  def protocol_drugs_by_category
    @drug_categories ||= @protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
  end

  def call
    patient_counts = Patient.where(assigned_facility: @facilities.map(&:id)).group(:assigned_facility).count
    drug_stocks = DrugStock.latest_for_facilities(@facilities, @for_end_of_month)

    @facilities.each_with_object({}) do |facility, report|
      facility_patient_count = patient_counts[facility] || 0
      report[facility.id] = drug_stock_for_facility(facility, facility_patient_count, drug_stocks[facility.id])
    end
  end

  def drug_stock_for_facility(facility, patient_count, facility_drug_stocks)
    facility_report = {}
    facility_report[:patient_count] = patient_count
    return facility_report if facility_drug_stocks.nil?

    drug_stocks = facility_drug_stocks.group_by { |drug_stock| drug_stock.protocol_drug.drug_category }
    protocol_drugs_by_category.each do |(drug_category, _protocol_drugs)|
      facility_report[drug_category] = {
        drug_stocks: drug_stocks[drug_category],
        patient_days: patient_days(facility, drug_category, drug_stocks[drug_category], patient_count)
      }
    end
    facility_report
  end

  def drug_stocks_by_rxnorm_code(drug_stocks)
    drug_stocks.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.rxnorm_code] = drug_stock
    }
  end

  def patient_days(facility, drug_category, drug_stocks, patient_count)
    coefficients = patient_days_coefficients[facility.state]
    stocks_on_hand = stocks_on_hand(coefficients, drug_category, drug_stocks)
    new_patient_coefficient = coefficients[:drug_categories][drug_category][:new_patient_coefficient]
    estimated_patients = patient_count * coefficients[:load_factor] * new_patient_coefficient
    { stocks_on_hand: stocks_on_hand,
      estimated_patients: estimated_patients,
      patient_days: (stocks_on_hand.map { |stock| stock[:in_stock] }.reduce(:+) / estimated_patients).floor }
  rescue
    # either drug stock is nil, or drug is not in formula
    :error
  end

  def stocks_on_hand(coefficients, drug_category, drug_stocks)
    stocks_by_rxnorm = drug_stocks_by_rxnorm_code(drug_stocks)
    protocol_drugs_by_category[drug_category].map do |protocol_drug|
      rxnorm_code = protocol_drug.rxnorm_code
      coefficient = coefficients[:drug_categories][drug_category][rxnorm_code]
      in_stock = stocks_by_rxnorm[rxnorm_code].in_stock
      { protocol_drug: protocol_drug,
        in_stock: in_stock,
        coefficient: coefficient,
        stock_on_hand: coefficient * in_stock }
    end
  end

  def patient_days_coefficients
    # move this to config
    { "Karnataka":
        { load_factor: 1,
          drug_categories:
            { "hypertension_ccb":
                { new_patient_coefficient: 1.4,
                  "329528": 1,
                  "329526": 2 },
              "hypertension_arb":
                { new_patient_coefficient: 0.37,
                  "316764": 1,
                  "316765": 2,
                  "979467": 1 },
              "hypertension_diuretic":
                { new_patient_coefficient: 0.06,
                  "316049": 1,
                  "331132": 1 } } },
      "Punjab":
        { load_factor: 1,
          drug_categories:
            { "hypertension_ccb":
                { new_patient_coefficient: 1.4,
                  "329528": 1,
                  "329526": 2 },
              "hypertension_arb":
                { new_patient_coefficient: 0.37,
                  "316764": 1,
                  "316765": 2,
                  "979467": 1 },
              "hypertension_diuretic":
                { new_patient_coefficient: 0.06,
                  "316049": 1,
                  "331132": 1 } } } }.with_indifferent_access
  end
end
