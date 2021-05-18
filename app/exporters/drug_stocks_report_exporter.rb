class DrugStocksReportExporter
  include MyFacilitiesHelper

  def self.csv(*args)
    new(*args).csv
  end

  def initialize(drug_stocks_query)
    @query = drug_stocks_query
    @drugs_by_category = drug_stocks_query.protocol_drugs_by_category
    @for_end_of_month = drug_stocks_query.for_end_of_month
  end

  def csv
    CSV.generate(headers: true) do |csv|
      csv << drug_categories_headers
      csv
    end
  end

  def drug_categories_headers
    left_pad_size = 1
    left_padding_columns = [nil] * left_pad_size

    left_padding_columns + @drugs_by_category.flat_map do |category, drugs|
      [protocol_drug_labels[category][:full], [nil] * drugs.count].flatten
    end
  end
end
