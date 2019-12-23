module AdminPage
  module Facilities
    class Index < ApplicationPage
      FACILITY_PAGE_HEADING = {css: 'h1.page-title'}.freeze
      UPLOAD_FACILITY_CSV_LINK={css: "nav.page-nav>a.btn-default"}
      ADD_FACILITY_GROUP_BUTTON = {css: 'nav.page-nav>a.btn-primary'}.freeze
      ORGANISATION_LIST = {css: 'h2'}.freeze

      def verify_facility_page_header
        present?(FACILITY_PAGE_HEADING)
        present?(UPLOAD_FACILITY_CSV_LINK)
        present?(ADD_FACILITY_GROUP_BUTTON)
      end

      def click_add_facility_group_button
        click(ADD_FACILITY_GROUP_BUTTON)
      end

      def is_edit_button_present_for_facilitygroup(name)
        within(:xpath, "//h3[text()='#{name}']/../..") do
          page.has_link?("Edit")
        end
      end

      def click_edit_button_present_for_facilitygroup(name)
        within(:xpath, "//h3[text()='#{name}']/../..") do
          find(:css,"a.btn-outline-primary").click
        end
      end
    end
  end
end

