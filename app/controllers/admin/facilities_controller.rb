class Admin::FacilitiesController < AdminController
  before_action :set_facility, only: [:show, :edit, :update, :destroy]

  def index
    @facilities = Facility.all
  end

  def show
  end

  def new
    @facility = Facility.new
  end

  def edit
  end

  def create
    @facility = Facility.new(facility_params)

    if @facility.save
      redirect_to [:admin, @facility], notice: 'Facility was successfully created.'
    else
      render :new
    end
  end

  def update
    if @facility.update(facility_params)
      redirect_to [:admin, @facility], notice: 'Facility was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @facility.destroy
    redirect_to admin_facilities_url, notice: 'Facility was successfully destroyed.'
  end

  private
    def set_facility
      @facility = Facility.find(params[:id])
    end

    def facility_params
      params.require(:facility).permit(
        :name,
        :street_address,
        :village_or_colony,
        :district,
        :state,
        :country,
        :pin,
        :facility_type
      )
    end
end
