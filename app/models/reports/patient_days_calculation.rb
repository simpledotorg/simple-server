module Reports
  class PatientDaysCalculation
    def initialize(state, protocol, drug_category, stocks_by_rxnorm_code, patient_count)
      @protocol = protocol
      @drug_category = drug_category
      @stocks_by_rxnorm_code = stocks_by_rxnorm_code
      @patient_count = patient_count
      @coefficients = patient_days_coefficients[state]
    end

    def protocol_drugs_by_category
      @protocol_drugs_by_category ||= @protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
    end

    def calculate
      return nil if stocks_on_hand.nil? || stocks_on_hand.empty?
      {stocks_on_hand: stocks_on_hand,
       patient_count: @patient_count,
       load_coefficient: @coefficients[:load_coefficient],
       new_patient_coefficient: new_patient_coefficient,
       estimated_patients: estimated_patients,
       patient_days: patient_days}
    rescue
      # either drug stock is nil, or drug is not in formula
      # Raise sentry error
      {patient_days: "error"}
    end

    def stocks_on_hand
      @stocks_on_hand ||= protocol_drugs_by_category[@drug_category].map do |protocol_drug|
        rxnorm_code = protocol_drug.rxnorm_code
        in_stock = @stocks_by_rxnorm_code[rxnorm_code]
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

    def patient_days_coefficients
      # move this to config
      {"Karnataka":
          {load_coefficient: 1,
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
          {load_coefficient: 1,
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
end
