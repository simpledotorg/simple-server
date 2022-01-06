# frozen_string_literal: true

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
      csv << district_warehouse_consumption_row
      facility_rows.each { |row| csv << row }
    end
  end

  def timestamp
    ["Report last updated at:", @report&.fetch(:last_updated_at)]
  end

  def drug_categories_header
    left_pad_size = 4
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

    ["Facilities", "Facility type", "Facility size", I18n.t("region_type.block").capitalize] + drug_name_cells + drug_category_name_cells
  end

  def total_consumption_row
    drug_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, drugs|
        drugs.map do |drug|
          consumed = @report[:total_drug_consumption].dig(drug_category, drug, :consumed)
          formatted_consumption_value(consumed)
        end
      end

    overall_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, _drugs|
        total = @report.dig(:total_drug_consumption, drug_category, :base_doses, :total)
        formatted_consumption_value(total)
      end

    ["All", "", "", ""] + drug_consumption_cells + overall_consumption_cells
  end

  def district_warehouse_consumption_row
    drug_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, drugs|
        drugs.map do |drug|
          consumed = @report[:district_drug_consumption].dig(drug_category, drug, :consumed)
          formatted_consumption_value(consumed)
        end
      end

    overall_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, _drugs|
        total = @report.dig(:district_drug_consumption, drug_category, :base_doses, :total)
        formatted_consumption_value(total)
      end

    ["District Warehouse", "", "", ""] + drug_consumption_cells + overall_consumption_cells
  end

  def facility_rows
    @query.facilities.with_region_information.order(:name).map do |facility|
      facility_row(facility)
    end
  end

  def facility_row(facility)
    drug_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, drugs|
        drugs.map do |drug|
          consumed = @report[:drug_consumption_by_facility_id].dig(facility.id, drug_category, drug, :consumed)
          formatted_consumption_value(consumed)
        end
      end

    overall_consumption_cells =
      @drugs_by_category.flat_map do |drug_category, _drugs|
        total = @report[:drug_consumption_by_facility_id].dig(facility.id, drug_category, :base_doses, :total)
        formatted_consumption_value(total)
      end

    [facility.name, facility.facility_type, facility.localized_facility_size, facility.block_name] + drug_consumption_cells + overall_consumption_cells
  end

  def formatted_consumption_value(consumption_value)
    if consumption_value.nil? || consumption_value == "error"
      "?"
    else
      consumption_value
    end
  end
end
