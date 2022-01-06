# frozen_string_literal: true

module AdminPage
  module Users
    class Index < ApplicationPage
      PAGE_TITLE = {css: "div.page-header"}.freeze
      DISTRICT_DROPDOWN = {css: "select[name='district']"}.freeze
      PAGE_DROPDOWN = {css: "select[name='per_page']"}.freeze
      FACILITY_NAME = {id: "facility_name"}.freeze
      REASON_FOR_DENIAL_EDITBOX = {id: "reason_for_denial"}.freeze
      DENY_ACCESS_BUTTON = {css: "input[value='Deny Access']"}.freeze

      def verify_user_landing_page
        present?(PAGE_TITLE)
        present?(DISTRICT_DROPDOWN)
        present?(PAGE_DROPDOWN)
        page.has_content?("All districts")
        page.has_content?("Per page")
      end

      def click_on_district_dropdown
        click(DISTRICT_DROPDOWN)
      end

      def get_all_districts_name
        click_on_district_dropdown
        find(:css, "select[name='district']").all("option").collect(&:text)
      end

      def select_district(name)
        within("#district-selector") do
          select name, from: "district"
        end
      end

      def get_all_user_count
        find_all(:css, "div.card").size
      end

      def get_all_user(district_name)
        find_all(:xpath, "//div[@name='" + district_name + "']").size
      end

      def deny_access(user_name)
        within(:xpath, "//div[@name='" + user_name + "']") do
          find(:css, "a.btn-outline-danger").click
        end
        type(REASON_FOR_DENIAL_EDITBOX, "incorrect mobile")
        click(DENY_ACCESS_BUTTON)
      end

      def allow_access(user_name)
        within(:xpath, "//div[@name='" + user_name + "']") do
          page.accept_alert do
            find("a.btn-outline-success").click
          end
        end
      end

      def click_edit_button(user_name)
        within(:xpath, "//div[@name='" + user_name + "']") do
          find(:xpath, "//div[@name='" + user_name + "']//a[text()='Edit']").click
        end
      end

      def is_facility_name_present(name)
        verify_text(FACILITY_NAME, name)
      end
    end
  end
end
