class DrugStocksReport

  def initialize(facilities:, for_end_of_month:)
    @facilities = facilities
    @for_end_of_month = for_end_of_month
    @patient_counts = Patient.where(assigned_facility: @facilities.map(&:id)).group(:assigned_facility).count
    @latest_drug_stocks = DrugStock.latest_for_facilities(@facilities, for_end_of_month)

    # assuming that all facilities on the page have the same protocol
    @protocol = @facilities.first.protocol
    @drug_stocks_all = DrugStock.first

    @drug_categories = @protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
  end

  def call
    @patient_counts.each_with_object({}) do |(facility, patient_count), report|
      report[facility.id] = {}
      report[facility.id][:patient_count] = patient_count
      next if @latest_drug_stocks[facility.id].nil?
      @drug_categories.each do |(drug_category, protocol_drugs)|
        drug_stocks = @latest_drug_stocks[facility.id].select { |drug_stock| drug_stock.protocol_drug.drug_category == drug_category }
        report[facility.id][drug_category] = {
          ## key this by name
          drug_stocks: drug_stocks,
          patient_days: patient_days(facility, drug_category, protocol_drugs, key_by_rxnorm(drug_stocks), patient_count)
        }
      end
    end
  end

  def key_by_rxnorm(latest_drug_stocks)
    latest_drug_stocks.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.rxnorm_code] = drug_stock
    }
  end

  def patient_days(facility, drug_category, protocol_drugs, drug_stocks, patient_count)
    begin
      coefficients = patient_days_coefficients[facility.state]
      numerator = protocol_drugs.map(&:rxnorm_code).map { |rxnorm_code|
        drug_stocks[rxnorm_code].in_stock * coefficients[:drug_categories][drug_category][rxnorm_code]
      }.reduce(:+)
      denominator = patient_count * coefficients[:load_factor] * coefficients[:drug_categories][drug_category][:new_patient_coefficient]
      (numerator / denominator).floor
    rescue
      # either drug stock is nil, or drug is not in formula
      :error
    end
  end

  def patient_days_coefficients
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
                  "331132": 1 }, }
        }
    }.with_indifferent_access
  end
end
