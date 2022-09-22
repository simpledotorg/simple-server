class ProgressTab::DrugStockComponent < ApplicationComponent
  include MyFacilitiesHelper
  attr_reader :drug_stocks_query
  attr_reader :drugs_by_category
  attr_reader :current_facility

  def initialize(drug_stocks_query:, drugs_by_category:, current_facility:)
    @drug_stocks_query = drug_stocks_query
    @drugs_by_category = drugs_by_category
    @current_facility = current_facility
  end

  def render?
    @drug_stocks_query.present?
  end
end
