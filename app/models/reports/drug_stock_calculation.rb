module Reports
  class DrugStockCalculation
    def initialize(state:,
      protocol:,
      drug_category:,
      stocks_by_rxnorm_code:,
      patient_count: nil,
      previous_month_stocks_by_rxnorm_code: nil)
      @protocol = protocol
      @drug_category = drug_category
      @stocks_by_rxnorm_code = stocks_by_rxnorm_code
      @previous_month_stocks_by_rxnorm_code = previous_month_stocks_by_rxnorm_code
      @patient_count = patient_count
      @coefficients = patient_days_coefficients(state)
    end

    def protocol_drugs_by_category
      @protocol_drugs_by_category ||= @protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
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
      Sentry.capture_message("Patient Days Calculation Error",
        extra: {
          coefficients: @coefficients,
          drug_category: @drug_category,
          stocks_by_rxnorm_code: @stocks_by_rxnorm_code,
          patient_count: @patient_count,
          protocol: @protocol,
          exception: e
        },
        tags: {type: "reports"})
      {patient_days: "error"}
    end

    def consumption
      protocol_drugs = protocol_drugs_by_category[@drug_category]
      drug_consumption = protocol_drugs.each_with_object({}) { |protocol_drug, consumption|
        opening_balance = @previous_month_stocks_by_rxnorm_code&.dig(protocol_drug.rxnorm_code, :in_stock)
        received = @stocks_by_rxnorm_code&.dig(protocol_drug.rxnorm_code, :received)
        closing_balance = @stocks_by_rxnorm_code&.dig(protocol_drug.rxnorm_code, :in_stock)
        consumption[protocol_drug] = consumption_calculation(opening_balance, received, closing_balance)
      }
      drug_consumption[:base_doses] = base_doses(drug_consumption)
      drug_consumption
    rescue => e
      # drug is not in formula, or other configuration error
      Sentry.capture_message("Consumption Calculation Error",
        extra: {
          coefficients: @coefficients,
          drug_category: @drug_category,
          stocks_by_rxnorm_code: @stocks_by_rxnorm_code,
          previous_month_stocks_by_rxnorm_code: @previous_month_stocks_by_rxnorm_code,
          patient_count: @patient_count,
          protocol: @protocol,
          exception: e
        },
        tags: {type: "reports"})
      {consumption: "error"}
    end

    def stocks_on_hand
      @stocks_on_hand ||= protocol_drugs_by_category[@drug_category].map do |protocol_drug|
        rxnorm_code = protocol_drug.rxnorm_code
        drug_stock = @stocks_by_rxnorm_code&.dig(rxnorm_code)
        in_stock = drug_stock[:in_stock] if drug_stock
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

    def consumption_calculation(opening_balance, received, closing_balance)
      return {consumed: nil} if [opening_balance, received, closing_balance].all?(&:nil?)

      {
        opening_balance: opening_balance,
        received: received,
        closing_balance: closing_balance,
        consumed: opening_balance + received - closing_balance
      }
    rescue => e
      Sentry.capture_message("Consumption Calculation Error",
        extra: {
          protocol: @protocol,
          opening_balance: opening_balance,
          received: received,
          closing_balance: closing_balance,
          exception: e
        },
        tags: {type: "reports"})
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
  end
end
