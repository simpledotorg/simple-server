module AdminPage
  module Facilities
    class Show < ApplicationPage
      FACILITY_PAGE_HEADING = {css: "h1.page-title"}.freeze
      UPLOAD_FACILITY_CSV_LINK = {css: ".page-nav>a.btn-outline-primary"}.freeze
      ADD_FACILITY_GROUP_BUTTON = {css: ".page-nav>a.btn-success"}.freeze
      ORGANISATION_LIST = {css: "h2"}.freeze

      def verify_facility_page_header
        present?(FACILITY_PAGE_HEADING)
        present?(UPLOAD_FACILITY_CSV_LINK)
        present?(ADD_FACILITY_GROUP_BUTTON)
      end

      def click_add_facility_group_button
        click(ADD_FACILITY_GROUP_BUTTON)
      end

      def is_edit_button_present_for_facilitygroup(name)
        present?({css: "a.spec-edit-#{name}-button"})
      end

      def click_edit_button_present_for_facilitygroup(name)
        find(:css, "a.spec-edit-#{name}-button").click
      end
    end
  end
end
