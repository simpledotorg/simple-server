class DrRai::ActionPlansController < AdminController
  before_action :authorize_user
  before_action :hydrate_plan, only: [:create]
  before_action :set_dr_rai_action_plan, only: %i[update destroy]
  before_action :authorize_edit_action_plans, only: [:update]
  before_action :enforce_action_plan_edit_window, only: [:update]

  # POST /dr_rai/action_plans or /dr_rai/action_plans.json
  def create
    DrRai::ActionPlan.transaction do
      @dr_rai_action_plan = DrRai::ActionPlan.new(
        statement: dr_rai_action_plan_params[:statement],
        dr_rai_indicator: @indicator,
        dr_rai_target: @target,
        region: @region
      )
      @dr_rai_action_plan.save!
      @dr_rai_action_plan.replace_action_items!(action_item_attributes)
    end

    redirect_to reports_region_path(report_scope: "facility", id: dr_rai_action_plan_params[:region_slug])
  rescue ActiveRecord::RecordInvalid
    render json: @dr_rai_action_plan&.errors || {}, status: :unprocessable_entity
  end

  # PATCH/PUT /dr_rai/action_plans/1 or /dr_rai/action_plans/1.json
  def update
    @dr_rai_action_plan.replace_action_items!(action_item_attributes)
    head :no_content
  rescue ActiveRecord::RecordInvalid
    render json: @dr_rai_action_plan.errors, status: :unprocessable_entity
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
    return if Flipper.enabled?(:dr_rai_manual_edit)

    target_period = Period.new(type: :quarter, value: @dr_rai_action_plan.target.period)
    current_period = Period.current.to_quarter_period

    unless target_period == current_period && Date.current.month != current_period.end.month
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
      :action_items_json,
      :indicator_id,
      :period,
      :region_slug,
      :statement,
      :target_type,
      :target_value
    )
  end

  def action_item_attributes
    plan_params = params.require(:dr_rai_action_plan)
    if plan_params.key?(:action_items_json)
      parse_action_items_json(plan_params[:action_items_json])
    else
      DrRai::ActionPlan.items_from_actions_text(plan_params[:actions]).map { |body| {body: body} }
    end
  end

  def parse_action_items_json(raw)
    parsed = JSON.parse(raw.presence || "[]")
    return [] unless parsed.is_a?(Array)

    parsed.map do |item|
      item = item.stringify_keys
      {id: item["id"], body: item["body"]}
    end
  rescue JSON::ParserError
    []
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
