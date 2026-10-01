class DrRai::ActionItemsController < AdminController
  before_action :set_action_item
  before_action :authorize_action_item
  before_action :enforce_completion_window

  def update
    completed = ActiveModel::Type::Boolean.new.cast(params[:completed])
    if @action_item.update(completed_at: completed ? Time.current : nil)
      render json: {id: @action_item.id, completed: @action_item.completed?}
    else
      render json: @action_item.errors, status: :unprocessable_entity
    end
  end

  private

  def set_action_item
    @action_item = DrRai::ActionItem.find(params[:id])
  end

  def authorize_action_item
    authorize {
      current_admin
        .accessible_facility_regions(:view_reports)
        .find(@action_item.action_plan.region_id)
    }
  end

  def enforce_completion_window
    head :forbidden unless @action_item.action_plan.tasks_checkable?
  end
end
