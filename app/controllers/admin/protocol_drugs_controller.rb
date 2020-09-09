class Admin::ProtocolDrugsController < AdminController
  before_action :set_protocol
  before_action :set_protocol_drug, only: [:show, :edit, :update, :destroy]

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_authorization_attempted, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }


  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.power_user? }
      @protocol_drugs = current_admin.accessible_protocol_drugs(:manage).order(:name)
    else
      authorize([:manage, ProtocolDrug])
      @protocol_drugs = policy_scope([:manage, ProtocolDrug])
    end
  end

  def show
  end

  def new
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.power_user? }
      @protocol_drug = @protocol.protocol_drugs.new
    else
      @protocol_drug = @protocol.protocol_drugs.new
      authorize([:manage, @protocol_drug])
    end
  end

  def edit
  end

  def create
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.power_user? }
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
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      @protocol_drug = authorize1 { current_admin.accessible_protocol_drugs(:manage).find(params[:id]) }
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
