class MyFacilities::DrugStocksController < AdminController
  include Pagination
  include MyFacilitiesFiltering

  layout "my_facilities"

  before_action :authorize_my_facilities
  after_action :verify_authorization_attempted

  DRUG_CATECORIES = []

  def index
    @facilities = current_admin.accessible_facilities(:view_reports)
      .eager_load(facility_group: :protocol_drugs)
      .where(protocol_drugs: {stock_tracked: true})
  end

  def create
  end

  private

  def authorize_my_facilities
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end
end
