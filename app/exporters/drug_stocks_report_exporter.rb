class DrugStocksReportExporter
  include MyFacilitiesHelper

  def self.csv(*args)
    new(*args).csv
  end

  def initialize(drug_stocks_query)
    @query = drug_stocks_query
    @drugs_by_category = drug_stocks_query.protocol_drugs_by_category
    @report = @query.drug_stocks_report
    @for_end_of_month = drug_stocks_query.for_end_of_month
  end

  def csv
    CSV.generate(headers: true) do |csv|
      csv << timestamp
      csv << drug_categories_header
      csv << drug_names_header
      csv << total_stock_row
      @report[:facilities].map do |(_facility_id, facility_report)|
        csv << facility_row(facility_report)
      end

      csv
    end
  end

  def timestamp
    ["Report last updated at:", @report&.fetch(:last_updated_at)]
  end

  def drug_categories_header
    left_pad_size = 1
    left_padding_columns = [nil] * left_pad_size

    left_padding_columns + @drugs_by_category.flat_map do |category, drugs|
      [protocol_drug_labels[category][:full], [nil] * drugs.count].flatten
    end
  end

  def drug_names_header
    ["Facilities"] +
      @drugs_by_category.flat_map do |_drug_category, drugs|
        drug_columns = drugs.map do |drug|
          "#{drug.name} #{drug.dosage}"
        end
        drug_columns << "Patient days"
      end
  end

  def total_stock_row
    ["All"] +
      @drugs_by_category.flat_map do |drug_category, drugs|
        patient_days = @report.dig(:all, drug_category, :patient_days)

        drugs.map do |drug|
          @report.dig(:all, drug_category, :drug_stocks, drug.rxnorm_code, :in_stock)
        end << patient_days
      end
  end

  def facility_row(facility_report)
    facility_name = facility_report[:facility].name

    [facility_name] +
      @drugs_by_category.flat_map do |drug_category, drugs|
        patient_days = facility_report.dig(drug_category, :patient_days)

        drugs.map do |drug|
          facility_report.dig(drug_category, :drug_stocks, drug.id)
        end << patient_days
      end
  end
end
