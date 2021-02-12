module Reports
  class PatientDaysCalculation
    def initialize(state:, protocol:, drug_category:, stocks_by_rxnorm_code:, patient_count:)
      @protocol = protocol
      @drug_category = drug_category
      @stocks_by_rxnorm_code = stocks_by_rxnorm_code
      @patient_count = patient_count
      @coefficients = patient_days_coefficients(state)
    end

    def protocol_drugs_by_category
      @protocol_drugs_by_category ||= @protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
    end

    def calculate
      return nil if stocks_on_hand.empty?
      {stocks_on_hand: stocks_on_hand,
       patient_count: @patient_count,
       load_coefficient: @coefficients[:load_coefficient],
       new_patient_coefficient: new_patient_coefficient,
       estimated_patients: estimated_patients,
       patient_days: patient_days}
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

    def stocks_on_hand
      @stocks_on_hand ||= protocol_drugs_by_category[@drug_category].map do |protocol_drug|
        rxnorm_code = protocol_drug.rxnorm_code
        in_stock = @stocks_by_rxnorm_code&.dig(rxnorm_code)
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

    def patient_days
      (stocks_on_hand.map { |stock| stock[:stock_on_hand] }.reduce(:+) / estimated_patients).floor
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
