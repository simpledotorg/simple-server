class Admin::ProtocolsController < AdminController
  before_action :set_protocol, only: [:show, :edit, :update, :destroy]

  skip_after_action :verify_authorized, if: -> { current_admin.permissions_v2_enabled? }
  skip_after_action :verify_policy_scoped, if: -> { current_admin.permissions_v2_enabled? }
  after_action :verify_authorization_attempted, if: -> { current_admin.permissions_v2_enabled? }

  def index
    if current_admin.permissions_v2_enabled?
      authorize1 { current_admin.accessible_organizations(:manage).any? }
      @protocols = current_admin.accessible_protocols(:manage).order(:name)
    else
      authorize([:manage, Protocol])
      @protocols = policy_scope([:manage, Protocol]).order(:name)
    end
  end

  def show
    @protocol_drugs = @protocol.protocol_drugs
  end

  def new
    if current_admin.permissions_v2_enabled?
      authorize1 { current_admin.accessible_organizations(:manage).any? }
      @protocol = Protocol.new
    else
      @protocol = Protocol.new
      authorize([:manage, @protocol])
    end
  end

  def edit
  end

  def create
    if current_admin.permissions_v2_enabled?
      authorize1 { current_admin.accessible_organizations(:manage).any? }
      @protocol = Protocol.new(protocol_params)
    else
      @protocol = Protocol.new(protocol_params)
      authorize([:manage, @protocol])
    end

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
    if current_admin.permissions_v2_enabled?
      @protocol = authorize1 { current_admin.accessible_protocols(:manage).find(params[:id]) }
    else
      @protocol = Protocol.find(params[:id])
      authorize([:manage, @protocol])
    end
  end

  def protocol_params
    params.require(:protocol).permit(:name, :follow_up_days)
  end
end
