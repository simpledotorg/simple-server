module PatientPage
  class Index < ApplicationPage

    INFORMATION = {css: 'p.info'}.freeze
    FACILITY_DROPDOWN = {css: "select[name='facility_id']"}.freeze
    PAGE_DROPDOWN = {css: "select[name='per_page']"}.freeze
    PATIENT_CARD = {css: "div.card"}.freeze
    PAGE_LINK={css: "a.page-link"}.freeze

    def verify_adherence_follow_up_landing_page
      present?(INFORMATION)
      present?(FACILITY_DROPDOWN)
      present?(PAGE_DROPDOWN)
    end

    def click_facility_drop_down
      click(FACILITY_DROPDOWN)
    end

    def get_all_facility_count
      click(FACILITY_DROPDOWN)
      all_option = find(:css, "select[name='facility_id']").all("option").collect(&:text)
      all_option.length
    end

    def click_page_dropdown
      click(PAGE_DROPDOWN)
    end

    def get_all_page_dropdown
      click(PAGE_DROPDOWN)
      all_option = find(:css, "select[name='per_page']").all("option").collect(&:text)
      all_option.length
    end

    def select_facility(value)
      within("#facility-selector") do
        select value, from: "facility_id"
      end
    end

    def get_all_patient_count
      all_elements(PATIENT_CARD)
    end

    def get_page_link
      all_elements(PAGE_LINK)
    end

    def select_page_dropdown(value)
      within("#limit-selector") do
        select value, from: "per_page"
      end
    end
  end
end


