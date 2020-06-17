class PatientsController < AdminController
  include FacilityFiltering
  include Pagination
  include SearchHelper

  # This controller / page does not have unit-tests since it's potentially throwaway work.
  # If we decide to continue using this, we should invest in testing it.
  #
  # Because of its throwaway nature, it intentionally piggybacks on the
  # view_overdue_list permission to avoid making a hyper-specific permission for this change.
  def lookup
    set_page
    set_per_page
    set_facility_id
    authorize([:overdue_list, Patient])

    @patients =
      if current_facility
        paginate(policy_scope([:overdue_list, Patient])
                   .where(registration_facility: current_facility)
                   .search_by_address(search_query))
      else
        paginate(policy_scope([:overdue_list, Patient])
                   .search_by_address(search_query))
      end
  end

  private

  def page
    params[:patient][:page]
  end
end
