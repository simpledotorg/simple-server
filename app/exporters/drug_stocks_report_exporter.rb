# frozen_string_literal: true

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
      csv << district_warehouse_stock_row
      facility_rows.each { |row| csv << row }
      csv
    end
  end

  def timestamp
    ["Report last updated at:", @report&.fetch(:last_updated_at)]
  end

  def drug_categories_header
    left_pad_size = 4
    left_padding_columns = [nil] * left_pad_size

    left_padding_columns + @drugs_by_category.flat_map do |category, drugs|
      [protocol_drug_labels[category][:full], [nil] * drugs.count].flatten
    end
  end

  def drug_names_header
    ["Facilities", "Facility type", "Facility size", I18n.t("region_type.block").capitalize] +
      @drugs_by_category.flat_map do |_drug_category, drugs|
        drug_columns = drugs.map do |drug|
          "#{drug.name} #{drug.dosage}"
        end
        drug_columns << "Patient days"
      end
  end

  def total_stock_row
    ["All", "", "", ""] +
      @drugs_by_category.flat_map do |drug_category, drugs|
        patient_days = @report.dig(:total_patient_days, drug_category, :patient_days)

        drugs.map do |drug|
          @report.dig(:total_drugs_in_stock, drug.rxnorm_code)
        end << patient_days
      end
  end

  def district_warehouse_stock_row
    ["District Warehouse", "", "", ""] +
      @drugs_by_category.flat_map do |drug_category, drugs|
        patient_days = @report.dig(:district_patient_days, drug_category, :patient_days)

        drugs.map do |drug|
          @report.dig(:district_drugs_in_stock, drug.rxnorm_code)
        end << patient_days
      end
  end

  def facility_rows
    @query.facilities.with_region_information.order(:name).map do |facility|
      facility_row(facility)
    end
  end

  def facility_row(facility)
    [facility.name, facility.facility_type, facility.localized_facility_size, facility.block_name] +
      @drugs_by_category.flat_map do |drug_category, drugs|
        patient_days = @report[:patient_days_by_facility_id].dig(facility.id, drug_category, :patient_days)

        drugs.map do |drug|
          @report[:drugs_in_stock_by_facility_id].dig([facility.id, drug.rxnorm_code])
        end << patient_days
      end
  end
end
