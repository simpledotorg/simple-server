class Admin::ProtocolDrugsController < AdminController
  before_action :set_protocol
  before_action :set_protocol_drug, only: [:show, :edit, :update, :destroy]

  skip_after_action :verify_authorized, if: -> { current_admin.permissions_v2_enabled? }
  skip_after_action :verify_policy_scoped, if: -> { current_admin.permissions_v2_enabled? }
  after_action :verify_authorization_attempted, if: -> { current_admin.permissions_v2_enabled? }

  def index
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_organizations(:manage).any? }
      @protocol_drugs = current_admin.accessible_protocol_drugs(:manage).order(:name)
    else
      authorize([:manage, ProtocolDrug])
      @protocol_drugs = policy_scope([:manage, ProtocolDrug])
    end
  end

  def show
  end

  def new
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_organizations(:manage).any? }
      @protocol_drug = @protocol.protocol_drugs.new
    else
      @protocol_drug = @protocol.protocol_drugs.new
      authorize([:manage, @protocol_drug])
    end
  end

  def edit
  end

  def create
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_organizations(:manage).any? }
      @protocol_drug = @protocol.protocol_drugs.new(protocol_drug_params)
    else
      @protocol_drug = @protocol.protocol_drugs.new(protocol_drug_params)
      authorize([:manage, @protocol_drug])
    end

    if @protocol_drug.save
      redirect_to [:admin, @protocol], notice: "Protocol drug was successfully created."
    else
      render :new
    end
  end

  def update
    if @protocol_drug.update(protocol_drug_params)
      redirect_to [:admin, @protocol], notice: "Protocol drug was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @protocol_drug.destroy
    redirect_to [:admin, @protocol], notice: "Protocol drug was successfully deleted."
  end

  private

  def set_protocol
    @protocol = Protocol.find(params[:protocol_id])
  end

  def set_protocol_drug
    if current_admin.permissions_v2_enabled?
      @protocol_drug = authorize_v2 { current_admin.accessible_protocol_drugs(:manage).find(params[:id]) }
    else
      @protocol_drug = ProtocolDrug.find(params[:id])
      authorize([:manage, @protocol_drug])
    end
  end

  def protocol_drug_params
    params.require(:protocol_drug).permit(
      :name,
      :dosage,
      :rxnorm_code
    )
  end
end
