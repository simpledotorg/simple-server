class ManageDistrictRegionService
  def initialize(params)
    @district_region = params[:district_region]
    @new_blocks = params[:new_blocks] || []
    @remove_blocks = params[:remove_blocks] || []
    @set_state_region = params[:set_state_region]
    @state_name = params[:state_name]

    if @set_state_region && @state_name.blank?
      raise ArgumentError, "Specify a non-blank state name if you must set a state."
    end
  end

  def self.call(*args)
    unless Flipper.enabled?(:regions_prep)
      logger.info "Calls to #{self.name} are skipped until the regions_prep feature is turned on."
    end

    o = new(*args)
    o.update_blocks
    o.create_state
  end

  def update_blocks
    create_blocks && destroy_blocks
  end

  def create_state
    return unless set_state_region
    return if state_name.blank?

    attributes = {
      name: state_name,
      region_type: Region.region_types[:state],
      reparent_to: organization_region
    }

    Region.where(attributes).first || Region.create!(attributes)
  end

  delegate :logger, to: Rails

  private

  attr_reader :district_region, :new_blocks, :remove_blocks, :set_state_region, :state_name

  def organization_region
    district_region.organization
  end

  def create_blocks
    return if new_blocks.blank?

    new_blocks.map { |name|
      Region.create!(
        name: name,
        region_type: Region.region_types[:block],
        reparent_to: district_region
      )
    }
  end

  def destroy_blocks
    return if remove_blocks.blank?

    remove_blocks.map { |id|
      Region.destroy(id) if Region.find(id) && Region.find(id).children.empty?
    }
  end
end
