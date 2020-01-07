module SizeFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_size, :set_facility_sizes

    private

    def set_size
      @size = params[:size].present? ? params[:size] : 'All'
    end

    def set_facility_sizes
      @facility_sizes = Facility.facility_sizes.keys.reverse
    end

    def facilities_by_size(scope_namespace = [])
      @facilities = (@size == 'All') ? Facility.all : Facility.where(facility_size: @size)
      policy_scope(scope_namespace.concat([@facilities]))
    end
  end
end
