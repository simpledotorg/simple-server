class Admin::ProtocolDrugsController < AdminController
  before_action :set_protocol
  before_action :set_protocol_drug, only: [:show, :edit, :update, :destroy]

  def index
    authorize ProtocolDrug
    @protocol_drugs = @protocol.protocol_drugs
  end

  def show
  end

  def new
    @protocol_drug = @protocol.protocol_drugs.new
    authorize @protocol_drug
  end

  def edit
  end

  def create
    @protocol_drug = @protocol.protocol_drugs.new(protocol_drug_params)
    authorize @protocol_drug

    if @protocol_drug.save
      redirect_to [:admin, @protocol], notice: 'Protocol drug was successfully created.'
    else
      render :new
    end
  end

  def update
    if @protocol_drug.update(protocol_drug_params)
      redirect_to [:admin, @protocol], notice: 'Protocol drug was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @protocol_drug.destroy
    redirect_to [:admin, @protocol], notice: 'Protocol drug was successfully destroyed.'
  end

  private

  def set_protocol
    @protocol = Protocol.find(params[:protocol_id])
  end

  def set_protocol_drug
    @protocol_drug = ProtocolDrug.find(params[:id])
    authorize @protocol_drug
  end

  def protocol_drug_params
    params.require(:protocol_drug).permit(
      :name,
      :dosage,
      :rxnorm_code
    )
  end
end
