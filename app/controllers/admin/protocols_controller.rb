class Admin::ProtocolsController < AdminController
  before_action :set_protocol, only: [:show, :edit, :update, :destroy]

  def index
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocols = current_admin.accessible_protocols(:manage).order(:name)
  end

  def show
    @protocol_drugs = @protocol.protocol_drugs
  end

  def new
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol = Protocol.new
  end

  def edit
  end

  def create
    authorize { current_admin.accessible_organizations(:manage).any? }
    @protocol = Protocol.new(protocol_params)

    if @protocol.save
      redirect_to [:admin, @protocol], notice: "Medication list was successfully created"
    else
      render :new
    end
  end

  def update
    if @protocol.update(protocol_params)
      redirect_to [:admin, @protocol], notice: "Medication list was successfully updated"
    else
      render :edit
    end
  end

  def destroy
    @protocol.destroy
    redirect_to admin_protocols_url, notice: "Medication list was successfully deleted"
  end

  def configure_coefficients
    @coefficients = ProtocolDrugCalculationCoefficient.find_by(protocol_params[:id]).coefficients
    if @coefficients.absent?
      @coefficients = {
        "load_coefficient": 0,
      }
      categories = Set.new
      @protocol.protocol_drugs.each do |drug|
        @coefficients[drug[:rxnorm_code]] = 0
        categories.add(drug[:drug_category])
      end
      categories.each do |category|
        @coefficients[category] = 0
      end
    end
  end

  def submit_coefficients
    if @coefficients.save
      redirect_to [:admin, @coefficients], notice: "Medication list was successfully configured"
    else
      render :configure_coefficients # renders with errors poopulated
    end
  end

  private

  def set_protocol
    @protocol = authorize { current_admin.accessible_protocols(:manage).find(params[:id]) }
  end

  def protocol_params
    params.require(:protocol).permit(:name, :follow_up_days)
  end
end
