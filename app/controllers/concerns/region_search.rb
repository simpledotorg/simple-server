# frozen_string_literal: true

module RegionSearch
  extend ActiveSupport::Concern

  included do
    def show_region_search
      @show_region_search ||= true
    end
  end
end
