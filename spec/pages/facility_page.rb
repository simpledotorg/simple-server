class FacilityPage < ApplicationPage

  FACILITY_PAGE_HEADING = {xpath: "//h1[text()='All facilities']"}.freeze
  ADD_FACILITY_GROUP_BUTTON = {xpath: "//a[@class='btn btn-sm btn-primary float-right']"}.freeze
  ORGANISATION_LIST = {xpath: '//h1'}.freeze
  NEW_FACILITY = {xpath: "//a[text()=' New Facility']"}.freeze
  FACILITY_GROUP_LIST = {xpath: "//h2"}
  EDIT_BUTTON = {xpath: "//div[@class='card-body']/a"}
  ADD_NEW_FACILITY = {xpath: "//a[text()='+ New Facility']"}.freeze
  FACILITY_LIST = {xpath: "//h5/a"}.freeze

  def click_add_facility_group_button
    click(ADD_FACILITY_GROUP_BUTTON)
  end

  def is_edit_button_present_for_facilitygroup(name)
    find(:xpath, "//h2[contains(text(),'#{name}')]//a").text.include? 'EDIT'
  end

  def click_edit_button_present_for_facility_group(name)
    find(:xpath, "//h2[contains(text(),'#{name}')]//a").click
  end

  def verify_facility_group_landing_page(facilities)
    present?(FACILITY_PAGE_HEADING)
    present?(NEW_FACILITY)
    present?(ADD_FACILITY_GROUP_BUTTON)
    list = all_elements(FACILITY_GROUP_LIST)
    list.each {|name| facilities.each {|fac_name| name.text.include?fac_name }}
  end

  def click_facility_edit_button
    click(EDIT_BUTTON)
  end

  def click_add_new_facility
    click(ADD_NEW_FACILITY)
  end

  def click_on_facility(name)
    elements = all_elements(FACILITY_LIST)
    elements.each {|ele| ele.click if ele.text.include? name}
  end
end


