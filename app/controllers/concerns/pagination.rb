# frozen_string_literal: true

module Pagination
  extend ActiveSupport::Concern

  DEFAULT_PAGE_SIZE = 20

  included do
    before_action :set_page, only: [:index, :show]
    before_action :set_per_page, only: [:index, :show]

    private

    def set_page
      @page = params[:page]
    end

    def set_per_page
      @per_page = params[:per_page] || DEFAULT_PAGE_SIZE
    end

    def paginate(records)
      paged_records = records.page(@page)
      return paged_records if records.size.zero?

      paged_records.per(@per_page == "All" ? records.size : @per_page.to_i)
    end
  end
end
