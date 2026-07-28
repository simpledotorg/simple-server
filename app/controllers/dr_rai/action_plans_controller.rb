class DrRai::ActionPlansController < AdminController
  before_action :authorize_user
  before_action :hydrate_plan, only: [:create]
  before_action :set_dr_rai_action_plan, only: %i[update destroy]
  before_action :authorize_edit_action_plans, only: [:update]
  before_action :enforce_action_plan_edit_window, only: [:update]

  # POST /dr_rai/action_plans or /dr_rai/action_plans.json
  def create
    @dr_rai_action_plan = DrRai::ActionPlan.new(
      statement: dr_rai_action_plan_params[:statement],
      actions: dr_rai_action_plan_params[:actions],
      dr_rai_indicator: @indicator,
      dr_rai_target: @target,
      region: @region
    )

    respond_to do |format|
      if @dr_rai_action_plan.save
        format.html { redirect_to reports_region_path(report_scope: "facility", id: dr_rai_action_plan_params[:region_slug]) }
      else
        format.html { render json: @dr_rai_action_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dr_rai/action_plans/1 or /dr_rai/action_plans/1.json
  def update
    if @dr_rai_action_plan.update(dr_rai_action_plan_update_params)
      head :no_content
    else
      render json: @dr_rai_action_plan.errors, status: :unprocessable_entity
    end
  end

  # DELETE /dr_rai/action_plans/1 or /dr_rai/action_plans/1.json
  def destroy
    @dr_rai_action_plan.discard

    respond_to do |format|
      format.html { redirect_to reports_region_path(report_scope: "facility", id: @dr_rai_action_plan.region.slug) }
      format.json { head :no_content }
    end
  end

  private

  def authorize_edit_action_plans
    authorize {
      current_admin
        .accessible_facility_regions(:view_reports)
        .find(@dr_rai_action_plan.region_id)
    }
  end

  # So… this one… may not be necessary — especially because the guard exists in
  # the component — but I have to guard against AI-generated code in the
  # future.
  def enforce_action_plan_edit_window
    target_period = Period.new(type: :quarter, value: @dr_rai_action_plan.target.period)
    current_period = Period.current.to_quarter_period

    unless target_period == current_period && Date.current.month == current_period.begin.month
      head :forbidden
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_dr_rai_action_plan
    @dr_rai_action_plan = DrRai::ActionPlan.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def dr_rai_action_plan_params
    params.require(:dr_rai_action_plan).permit(
      :actions,
      :indicator_id,
      :period,
      :region_slug,
      :statement,
      :target_type,
      :target_value
    )
  end

  def dr_rai_action_plan_update_params
    params.require(:dr_rai_action_plan).permit(:actions)
  end

  def authorize_user
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def hydrate_plan
    @region = Region.find_by slug: dr_rai_action_plan_params[:region_slug]
    @indicator = DrRai::Indicator.find(dr_rai_action_plan_params[:indicator_id])
    period = Period.new(type: :quarter, value: dr_rai_action_plan_params[:period])
    target_attributes = {
      type: dr_rai_action_plan_params[:target_type],
      period: period,
      indicator: @indicator
    }
    if dr_rai_action_plan_params[:target_value].present?
      target_attributes[:numeric_value] = dr_rai_action_plan_params[:target_value]
    end
    @target = DrRai::Target.create!(target_attributes)
  end
end
