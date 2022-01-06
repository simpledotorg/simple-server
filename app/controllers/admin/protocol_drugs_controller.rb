# frozen_string_literal: true

class Admin::ProtocolDrugsController < AdminController
  before_action :set_protocol
  before_action :set_protocol_drug, only: [:show, :edit, :update, :destroy]

  def index
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol_drugs = current_admin.accessible_protocol_drugs(:manage).order(:name)
  end

  def show
  end

  def new
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol_drug = @protocol.protocol_drugs.new
  end

  def edit
  end

  def create
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol_drug = @protocol.protocol_drugs.new(protocol_drug_params)

    if @protocol_drug.save
      redirect_to [:admin, @protocol], notice: "Medication was successfully created"
    else
      render :new
    end
  end

  def update
    if @protocol_drug.update(protocol_drug_params)
      redirect_to [:admin, @protocol], notice: "Medication was successfully updated"
    else
      render :edit
    end
  end

  def destroy
    @protocol_drug.destroy
    redirect_to [:admin, @protocol], notice: "Medication was successfully deleted"
  end

  private

  def set_protocol
    @protocol = Protocol.find(params[:protocol_id])
  end

  def set_protocol_drug
    @protocol_drug = authorize { current_admin.accessible_protocol_drugs(:manage).find(params[:id]) }
  end

  def protocol_drug_params
    params.require(:protocol_drug).permit(
      :name,
      :dosage,
      :rxnorm_code,
      :drug_category,
      :stock_tracked
    )
  end
end
