# frozen_string_literal: true

module AppointmentsPage
  class Index < ApplicationPage
    INFORMATION = {css: "p.info"}.freeze
    FACILITY_DROPDOWN = {css: "select[name='facility_id']"}.freeze
    PAGE_DROPDOWN = {css: "select[name='per_page']"}.freeze
    DOWNLOAD_HEADING = {css: "download_text"}.freeze
    DOWNLOAD_INFO_TEXT = {css: "div.text-grey"}.freeze
    PATIENT_CARD = {css: "div.card"}.freeze
    LIST = {xpath: "//select[@name='facility_id']/option"}.freeze
    DOWNLOAD_LINK = {css: "i.fa-file-excel.mr-2"}.freeze
    PAGE_LINK = {css: "a.page-link"}.freeze
    # OVERDUE_DAYS={css: "div.card-date"}.freeze
    LAST_INTERACTIONS = {css: "div.card-footer.text-info"}.freeze

    def verify_overdue_landing_page
      present?(INFORMATION)
      present?(FACILITY_DROPDOWN)
      present?(PAGE_DROPDOWN)
      present?(DOWNLOAD_HEADING)
      present?(DOWNLOAD_INFO_TEXT)
    end

    def select_facility_drop_down
      find(:xpath, "//select[@name='facility_id']/following-sibling::button").click
    end

    def get_all_facility_count
      select_facility_drop_down
      all_option = find(:css, "select[name='facility_id'] ~ .dropdown-menu").all("li").collect(&:text)
      # We subtract 1 to exclude the value of "All Facilities"
      all_option.length - 1
    end

    def select_page_dropdown
      click(PAGE_DROPDOWN)
    end

    def get_all_page_dropdown
      click(PAGE_DROPDOWN)
      all_option = find(:css, "select[name='per_page']").all("option").collect(&:text)
      all_option.length
    end

    def get_all_patient_count
      all_elements(PATIENT_CARD)
    end

    def select_facility(value)
      within("#facility-selector") do
        select value, from: "facility_id"
      end
    end

    def click_download_link
      page.accept_confirm do
        click_link "Download overdue list"
      end
    end

    def get_page_link_count
      all_elements(PAGE_LINK)
    end

    def get_overdue_days
      find("div.card-date").text
    end

    def get_last_interaction
      LAST_INTERACTIONS
    end
  end
end
