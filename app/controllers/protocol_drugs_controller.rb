class ProtocolDrugsController < ApplicationController
  before_action :set_protocol_drug, only: [:show, :edit, :update, :destroy]
  before_action :set_protocols, only: [:create, :edit, :update, :new]

  # GET /protocol_drugs
  # GET /protocol_drugs.json
  def index
    @protocol_drugs = ProtocolDrug.all
  end

  # GET /protocol_drugs/1
  # GET /protocol_drugs/1.json
  def show
  end

  # GET /protocol_drugs/new
  def new
    @protocol_drug = ProtocolDrug.new
  end

  # GET /protocol_drugs/1/edit
  def edit
  end

  # POST /protocol_drugs
  # POST /protocol_drugs.json
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

  # PATCH/PUT /protocol_drugs/1
  # PATCH/PUT /protocol_drugs/1.json
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

  # DELETE /protocol_drugs/1
  # DELETE /protocol_drugs/1.json
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

  # Use callbacks to share common setup or constraints between actions.
  def set_protocol_drug
    @protocol_drug = ProtocolDrug.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def protocol_drug_params
    params.require(:protocol_drug).permit(:name, :dosage, :rxnorm_code, :protocol_id)
  end
end
