module Reports
  class DrugStockCalculation
    include Memery
    def initialize(state:, protocol_drugs:, drug_category:, current_drug_stocks:, previous_drug_stocks: DrugStock.none, patient_count: nil)
      @protocol_drugs = protocol_drugs
      @drug_category = drug_category
      @current_drug_stocks = current_drug_stocks
      @previous_drug_stocks = previous_drug_stocks
      @patient_count = patient_count
      @coefficients = patient_days_coefficients(state)
    end

    def protocol_drugs_by_category
      @protocol_drugs_by_category ||= @protocol_drugs.group_by(&:drug_category)
    end

    def patient_days
      return nil if stocks_on_hand.empty?
      {stocks_on_hand: stocks_on_hand,
       patient_count: @patient_count,
       load_coefficient: @coefficients[:load_coefficient],
       new_patient_coefficient: new_patient_coefficient,
       estimated_patients: estimated_patients,
       patient_days: patient_days_calculation}
    rescue => e
      # drug is not in formula, or other configuration error
      error_info = {
        coefficients: @coefficients,
        drug_category: @drug_category,
        in_stock_by_rxnorm_code: in_stock_by_rxnorm_code,
        patient_count: @patient_count,
        protocol: @protocol,
        exception: e
      }

      trace("patient_days", "Reports::DrugStockCalculation#patient_days", error_info)

      {patient_days: "error"}
    end

    def consumption
      protocol_drugs = protocol_drugs_by_category[@drug_category]
      drug_consumption = protocol_drugs.each_with_object({}) { |protocol_drug, consumption|
        opening_balance = previous_month_in_stock_by_rxnorm_code&.dig(protocol_drug.rxnorm_code)
        received = received_by_rxnorm_code&.dig(protocol_drug.rxnorm_code)
        redistributed = redistributed_by_rxnorm_code&.dig(protocol_drug.rxnorm_code)
        closing_balance = in_stock_by_rxnorm_code&.dig(protocol_drug.rxnorm_code)
        consumption[protocol_drug] = consumption_calculation(opening_balance, received, redistributed, closing_balance)
      }
      drug_consumption[:base_doses] = base_doses(drug_consumption)
      drug_consumption
    rescue => e
      # drug is not in formula, or other configuration error
      error_info = {
        coefficients: @coefficients,
        drug_category: @drug_category,
        in_stock_by_rxnorm_code: in_stock_by_rxnorm_code,
        previous_month_in_stock_by_rxnorm_code: previous_month_in_stock_by_rxnorm_code,
        patient_count: @patient_count,
        protocol: @protocol,
        exception: e
      }

      trace("consumption", "Reports::DrugStockCalculation#consumption", error_info)

      {consumption: "error"}
    end

    def stocks_on_hand
      @stocks_on_hand ||= protocol_drugs_by_category[@drug_category].map do |protocol_drug|
        rxnorm_code = protocol_drug.rxnorm_code
        in_stock = in_stock_by_rxnorm_code&.dig(rxnorm_code)
        next if in_stock.nil?
        coefficient = drug_coefficient(rxnorm_code)
        {protocol_drug: protocol_drug,
         in_stock: in_stock,
         coefficient: coefficient,
         stock_on_hand: coefficient * in_stock}
      end&.compact
    end

    def drug_coefficient(rxnorm_code)
      @coefficients.dig(:drug_categories, @drug_category, rxnorm_code)
    end

    def drug_name_and_dosage(drug)
      "#{drug.name} #{drug.dosage}"
    end

    def patient_days_calculation
      (stocks_on_hand.map { |stock| stock[:stock_on_hand] }.reduce(:+) / estimated_patients).floor
    end

    def consumption_calculation(opening_balance, received, redistributed, closing_balance)
      return {consumed: nil} if [opening_balance, received, closing_balance].all?(&:nil?)

      {
        opening_balance: opening_balance,
        received: received,
        redistributed: redistributed,
        closing_balance: closing_balance,
        consumed: opening_balance + (received || 0) - (redistributed || 0) - closing_balance
      }
    rescue => e
      error_info = {
        protocol: @protocol,
        opening_balance: opening_balance,
        received: received,
        redistributed: redistributed,
        closing_balance: closing_balance,
        exception: e
      }

      trace("consumption_calculation", "Reports::DrugStockCalculation#consumption_calculation", error_info)

      {consumed: "error"}
    end

    def base_doses(drug_consumption)
      base_doses = {}
      base_doses[:drugs] = drug_consumption.map { |drug, consumption|
        {name: drug_name_and_dosage(drug),
         consumed: consumption[:consumed],
         coefficient: drug_coefficient(drug.rxnorm_code)}
      }
      base_doses[:total] = base_doses_calculation(base_doses[:drugs])
      base_doses
    end

    def base_doses_calculation(doses)
      doses
        .reject { |dose| dose[:consumed].nil? || dose[:consumed] == "error" }
        .map { |dose| dose[:consumed] * dose[:coefficient] }
        .reduce(:+)
    end

    def estimated_patients
      @estimated_patients ||= @patient_count * @coefficients[:load_coefficient] * new_patient_coefficient
    end

    def new_patient_coefficient
      @new_patient_coefficient ||= @coefficients.dig(:drug_categories, @drug_category, :new_patient_coefficient)
    end

    def patient_days_coefficients(state)
      drug_stock_config = Rails.application.config.drug_stock_config
      env = ENV.fetch("SIMPLE_SERVER_ENV")

      # This is a hack for convenience in envs with generated data
      # Once we make formula coefficients a first class model, we can get rid of this
      if env != "production" && drug_stock_config[state].nil?
        drug_stock_config.values.first
      else
        drug_stock_config[state]
      end
    end

    def drug_attribute_sum_by_rxnorm_code(drug_stocks, attribute)
      drug_stocks
        .select { |drug_stock| drug_stock[attribute].present? }
        .group_by { |drug_stock| drug_stock.protocol_drug.rxnorm_code }
        .map { |rxnorm_code, drug_stocks| [rxnorm_code, drug_stocks.pluck(attribute).sum] }
        .to_h
    end

    memoize def in_stock_by_rxnorm_code
      drug_attribute_sum_by_rxnorm_code(@current_drug_stocks, :in_stock)
    end

    memoize def received_by_rxnorm_code
      drug_attribute_sum_by_rxnorm_code(@current_drug_stocks, :received)
    end

    memoize def redistributed_by_rxnorm_code
      drug_attribute_sum_by_rxnorm_code(@current_drug_stocks, :redistributed)
    end

    memoize def previous_month_in_stock_by_rxnorm_code
      drug_attribute_sum_by_rxnorm_code(@previous_drug_stocks, :in_stock)
    end

    def trace(name, resource, error_info)
      Datadog.tracer.trace(name, resource: resource) do |span|
        error_info.each { |tag, value| span.set_tag(tag.to_s, value.to_s) }
      end
    end
  end
end
