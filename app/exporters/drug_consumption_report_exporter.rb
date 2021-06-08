class DrugConsumptionReportExporter
  include MyFacilitiesHelper

  def self.csv(*args)
    new(*args).csv
  end

  def initialize(drug_stocks_query)
    @query = drug_stocks_query
    @drugs_by_category = drug_stocks_query.protocol_drugs_by_category
    @report = @query.drug_consumption_report
    @for_end_of_month = drug_stocks_query.for_end_of_month
  end

  def csv
    CSV.generate(headers: true) do |csv|
      csv << timestamp
      csv << drug_categories_header
      csv << drug_names_header
      csv << total_consumption_row
      facility_rows.each { |row| csv << row }
    end
  end

  def timestamp
    ["Report last updated at:", @report&.fetch(:last_updated_at)]
  end

  def drug_categories_header
    left_pad_size = 1
    left_padding_columns = [nil] * left_pad_size

    drug_category_cells = left_padding_columns + @drugs_by_category.flat_map do |category, drugs|
      [protocol_drug_labels[category][:full], [nil] * (drugs.count - 1)].flatten
    end

    overall_cells = ["Overall in base doses"] + [nil] * (@drugs_by_category.count - 1)

    drug_category_cells + overall_cells
  end

  def drug_names_header
    drug_name_cells =
      @drugs_by_category.flat_map do |_drug_category, drugs|
        drugs.map { |drug| "#{drug.name} #{drug.dosage}" }
      end

    drug_category_name_cells =
      @drugs_by_category.keys.map do |category|
        "#{protocol_drug_labels[category][:short]} base doses"
      end

    ["Facilities"] + drug_name_cells + drug_category_name_cells
  end

  def total_consumption_row
    drug_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, drugs|
        drugs.map do |drug|
          consumed = @report[:all].dig(drug_category, drug, :consumed)
          formatted_consumption_value(consumed)
        end
      end

    overall_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, _drugs|
        total = @report.dig(:all, drug_category, :base_doses, :total)
        formatted_consumption_value(total)
      end

    ["All"] + drug_consumption_cells + overall_consumption_cells
  end

  def facility_rows
    @report[:facilities].map do |(_facility_id, facility_report)|
      facility_row(facility_report)
    end
  end

  def facility_row(facility_report)
    facility_name = facility_report[:facility].name

    drug_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, drugs|
        drugs.map do |drug|
          consumed = facility_report.dig(drug_category, drug, :consumed)
          formatted_consumption_value(consumed)
        end
      end

    overall_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, _drugs|
        total = facility_report.dig(drug_category, :base_doses, :total)
        formatted_consumption_value(total)
      end

    [facility_name] + drug_consumption_cells + overall_consumption_cells
  end

  def formatted_consumption_value(consumption_value)
    if consumption_value.nil? || consumption_value == "error"
      "?"
    else
      consumption_value
    end
  end
end
