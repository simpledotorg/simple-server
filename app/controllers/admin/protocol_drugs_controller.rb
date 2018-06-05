class Admin::ProtocolDrugsController < ApplicationController
  before_action :set_protocol_drug, only: %i[show edit update destroy]
  before_action :set_protocols, only: %i[create edit update new]

  def index
    @protocol_drugs = ProtocolDrug.all
  end

  def show
  end

  def new
    @protocol_drug = ProtocolDrug.new
  end

  def edit
  end

  def create
    @protocol_drug = ProtocolDrug.new(protocol_drug_params)
    if @protocol_drug.save
      redirect_to [:admin, :protocols], notice: 'Protocol drug was successfully created.'
    else
      render :new
    end
  end

  def update
    if @protocol_drug.update(protocol_drug_params)
      redirect_to [:admin, :protocols], notice: 'Protocol drug was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @protocol_drug.destroy
    redirect_to [:admin, :protocols], notice: 'Protocol drug was successfully destroyed.'
  end

  private

  def set_protocols
    @protocols = Protocol.all
  end

  def set_protocol_drug
    @protocol_drug = ProtocolDrug.find(params[:id])
  end

  def protocol_drug_params
    params.require(:protocol_drug).permit(:name, :dosage, :rxnorm_code, :protocol_id)
  end
end
