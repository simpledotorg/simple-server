class ProtocolDrugsController < ApplicationController
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

    respond_to do |format|
      if @protocol_drug.save
        format.html { redirect_to :protocols, notice: 'Protocol drug was successfully created.' }
        format.json { render :show, status: :created, location: @protocol_drug }
      else
        format.html { render :new }
        format.json { render json: @protocol_drug.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @protocol_drug.update(protocol_drug_params)
        format.html { redirect_to :protocols, notice: 'Protocol drug was successfully updated.' }
        format.json { render :show, status: :ok, location: @protocol_drug }
      else
        format.html { render :edit }
        format.json { render json: @protocol_drug.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @protocol_drug.destroy
    respond_to do |format|
      format.html { redirect_to protocol_drugs_url, notice: 'Protocol drug was successfully destroyed.' }
      format.json { head :no_content }
    end
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
