class Admin::ProtocolsController < AdminController
  before_action :set_protocol, only: [:show, :edit, :update, :destroy]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  after_action :verify_authorization_attempted

  def index
    authorize1 { current_admin.power_user? }
    @protocols = current_admin.accessible_protocols(:manage).order(:name)
  end

  def show
    @protocol_drugs = @protocol.protocol_drugs
  end

  def new
    authorize1 { current_admin.power_user? }
    @protocol = Protocol.new
  end

  def edit
  end

  def create
    authorize1 { current_admin.power_user? }
    @protocol = Protocol.new(protocol_params)

    if @protocol.save
      redirect_to [:admin, @protocol], notice: "Protocol was successfully created."
    else
      render :new
    end
  end

  def update
    if @protocol.update(protocol_params)
      redirect_to [:admin, @protocol], notice: "Protocol was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @protocol.destroy
    redirect_to admin_protocols_url, notice: "Protocol was successfully deleted."
  end

  private

  def set_protocol
    @protocol = authorize1 { current_admin.accessible_protocols(:manage).find(params[:id]) }
  end

  def protocol_params
    params.require(:protocol).permit(:name, :follow_up_days)
  end
end
