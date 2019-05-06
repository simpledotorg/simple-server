class FacilityPage < Base
  include Capybara::DSL

  FACILITY_PAGE_HEADING={xpath:"//h1[text()='All facilities']"}.freeze
  ADD_FACILITY_GROUP_BUTTON={xpath: "//a[@class='btn btn-sm btn-primary float-right']"}.freeze
  ORGANISATION_LIST={xpath: '//h1'}.freeze
  NEW_FACILITY={xpath: "//a[text()=' New Facility']"}.freeze


  def click_add_facility_group_button
    click(ADD_FACILITY_GROUP_BUTTON)
  end

  def is_edit_button_present_for_facilitygroup(name)
    find(:xpath,"//h2[contains(text(),'#{name}')]//a").text.include?'EDIT'
  end

  def click_edit_button_present_for_facilitygroup(name)
    find(:xpath,"//h2[contains(text(),'#{name}')]//a").click
  end

end