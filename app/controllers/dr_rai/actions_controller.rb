class DrRai::ActionsController < AdminController
  before_action :authorize_user
  before_action :set_dr_rai_action, only: %i[show edit update destroy]

  # GET /dr_rai/actions or /dr_rai/actions.json
  def index
    @dr_rai_actions = DrRai::Action.all
    @dr_rai_action = DrRai::Action.new
  end

  # POST /dr_rai/actions or /dr_rai/actions.json
  def create
    @dr_rai_action = DrRai::Action.new(dr_rai_action_params)

    respond_to do |format|
      if @dr_rai_action.save
        format.html { redirect_to dr_rai_actions_url, notice: "Action was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dr_rai/actions/1 or /dr_rai/actions/1.json
  def update
    respond_to do |format|
      if @dr_rai_action.update(dr_rai_action_params)
        format.json { render :show, status: :ok, location: @dr_rai_action }
      else
        format.json { render json: @dr_rai_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dr_rai/actions/1 or /dr_rai/actions/1.json
  def destroy
    @dr_rai_action.discard

    respond_to do |format|
      format.html { redirect_to dr_rai_actions_url, notice: "Action was successfully removed." }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dr_rai_action
    @dr_rai_action = DrRai::Action.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def dr_rai_action_params
    params.require(:dr_rai_action).permit(:description)
  end

  def authorize_user
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end
end
