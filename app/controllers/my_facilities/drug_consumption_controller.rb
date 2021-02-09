class MyFacilities::DrugConsumptionController < AdminController
  include Pagination
  include MyFacilitiesFiltering

  layout "my_facilities"

  before_action :authorize_my_facilities
  after_action :verify_authorization_attempted
  before_action :set_for_end_of_month
  before_action :drug_stocks_enabled?
  before_action :set_force_cache, only: [:index]

  def index
  end

  private

  def authorize_my_facilities
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def drug_stocks_enabled?
    unless current_admin.feature_enabled?(:drug_stocks)
      redirect_to :root
    end
  end

  def set_for_end_of_month
    @for_end_of_month ||= if params[:for_end_of_month]
      Date.strptime(params[:for_end_of_month], "%b-%Y").end_of_month
    else
      Date.today.end_of_month
    end
  end
end
