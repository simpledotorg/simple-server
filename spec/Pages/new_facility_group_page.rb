class FacilityGroupForm < Base

  include Capybara::DSL

  CREATE_FACILITY_GROUP_BUTTON = {xpath: "//input[@class='btn btn-primary']"}.freeze
  FACILITY_NAME = {id: 'facility_name'}.freeze
  FACILITY_DESCRIPTION = {id: 'facility_description'}.freeze
  DELETE_FACILITYGROUP_BUTTON = {xpath: "//nav[@class='page-nav']"}.freeze
  PROTOCOL_DROPDOWN={xpath: "//select[@name='facility_group[protocol_id]']"}.freeze
  UNASSOCIATED_FACILITY_CHECKBOX={xpath: "//input[@type='checkbox']"}.freeze
  SUCCESSFUL_MESSAGE={xpath:"//div[@class='alert alert-primary alert-dismissable fade show']"}.freeze
  MESSAGE_CROSS_BUTTON = {xpath: "//button[@type='button']/span"}.freeze
  UPDATE_FACILITY_GROUP_BUTTON = {xpath: "//input[@class='btn btn-primary']"}.freeze


  def select_organisation_name_dropdown(value)
    find(:xpath, "//select[@name='facility_group[organization_id]']").find(:option, value).select_option
  end

  def select_protocol_name_dropdown(value)
    find(:xpath, "//select[@name='facility_group[protocol_id]']").find(:option, value).select_option
  end

  def add_new_facility_group_without_assigningfacility(org_name, name, description, protocol_name)

    select_organisation_name_dropdown(org_name)
    type(FACILITY_NAME,name)
    type(FACILITY_DESCRIPTION,description)
    select_protocol_name_dropdown(protocol_name)
    click(CREATE_FACILITY_GROUP_BUTTON)
  end

  def add_new_facility_group(org_name, name, description,unassociatedfacility, protocol_name)

    select_organisation_name_dropdown(org_name)
    type(FACILITY_NAME,name)
    type(FACILITY_DESCRIPTION,description)
    select_unassociated_facility(unassociatedfacility)
    select_protocol_name_dropdown(protocol_name)
    click(CREATE_FACILITY_GROUP_BUTTON)
  end

  def is_delete_facilitygroup_button_present
    present?(DELETE_FACILITYGROUP_BUTTON)
  end

  def click_on_delete_facilitygroup_button
    click(DELETE_FACILITYGROUP_BUTTON)
    # page.accept_alert("OK")
    # present?(SUCCESSFUL_MESSAGE)
    # click(MESSAGE_CROSS_BUTTON)
  end

  def select_unassociated_facility(facility_name)
    find(:xpath,"//div[@class='form-check']/label[text()='#{facility_name}']").text.include?'testfacility'
    find(:xpath,"//div[@class='form-check']/label[text()='#{facility_name}']/../input").click
  end

  def click_on_update_facility_group_button
    click(UPDATE_FACILITY_GROUP_BUTTON)
  end
end
