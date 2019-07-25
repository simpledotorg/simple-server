class FacilityPage < ApplicationPage

  FACILITY_PAGE_HEADING = { css: 'h1.page-title' }.freeze
  ADD_FACILITY_GROUP_BUTTON = { css: 'a.btn.btn-sm.btn-primary' }.freeze
  ORGANISATION_LIST = { css: 'h2' }.freeze
  NEW_FACILITY = { css: 'a.btn.btn-default.float-right' }.freeze


  def click_add_facility_group_button
    click(ADD_FACILITY_GROUP_BUTTON)
  end

  def is_edit_button_present_for_facilitygroup(name)
    find(:xpath, "//h3[text()='#{name}']/../..//a[contains(@class,'btn-outline-primary')]").text.include? 'EDIT'
  end

  def click_edit_button_present_for_facilitygroup(name)
    find(:xpath, "//h3[text()='#{name}']/../..//a[contains(@class,'btn-outline-primary')]").click
  end

end