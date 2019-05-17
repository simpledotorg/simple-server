class FacilityGroupForm < ApplicationPage
  #this page is use for creating new facility group and edit facility group
  include Capybara::DSL

  PAGE_HEADING = {xpath: "//h1[text()='New facility group']"}
  CREATE_FACILITY_GROUP_BUTTON = {xpath: "//input[@class='btn btn-primary']"}.freeze
  FACILITY_NAME = {id: 'facility_name'}.freeze
  FACILITY_DESCRIPTION = {id: 'facility_description'}.freeze
  DELETE_FACILITY_GROUP_BUTTON = {xpath: "//nav[@class='page-nav']"}.freeze
  PROTOCOL_DROPDOWN = {xpath: "//select[@name='facility_group[protocol_id]']"}.freeze
  UNASSOCIATED_FACILITY_CHECKBOX = {xpath: "//input[@type='checkbox']"}.freeze
  SUCCESSFUL_MESSAGE = {xpath: "//div[@class='alert alert-primary alert-dismissable fade show']"}.freeze
  MESSAGE_CROSS_BUTTON = {xpath: "//button[@type='button']/span"}.freeze
  UPDATE_FACILITY_GROUP_BUTTON = {xpath: "//input[@class='btn btn-primary']"}.freeze
  ASSOCIATED_FACILITY_LABEL = {xpath: "//label[text()='Associated facilities']"}.freeze


  def select_organisation_dropdown(value)
    find(:xpath, "//select[@name='facility_group[organization_id]']").find(:option, value).select_option
  end

  def select_protocol_dropdown(value)
    find(:xpath, "//select[@name='facility_group[protocol_id]']").find(:option, value).select_option
  end

  def select_unassociated_facility(name)
    find(:xpath, "//div[@class='form-check']/label[text()='#{name}']/../input").click
  end

  def add_new_facility_group_without_assigning_facility(org_name, name, description, protocol_name)
    present?(PAGE_HEADING)
    select_organisation_dropdown(org_name)
    type(FACILITY_NAME, name)
    type(FACILITY_DESCRIPTION, description)
    select_protocol_dropdown(protocol_name)
    click(CREATE_FACILITY_GROUP_BUTTON)
  end

  def add_new_facility_group(org_name, name, description, unassociated_facility, protocol_name)
    present?(PAGE_HEADING)
    select_organisation_dropdown(org_name)
    type(FACILITY_NAME, name)
    type(FACILITY_DESCRIPTION, description)
    select_unassociated_facility(unassociated_facility)
    select_protocol_dropdown(protocol_name)
    click(CREATE_FACILITY_GROUP_BUTTON)
  end

  def is_delete_facility_group_button_present
    present?(DELETE_FACILITY_GROUP_BUTTON)
  end

  def click_on_delete_facilitygroup_button
    click(DELETE_FACILITY_GROUP_BUTTON)
    # page.accept_alert("OK")
    # present?(SUCCESSFUL_MESSAGE)
    # click(MESSAGE_CROSS_BUTTON)
  end


  def click_on_update_facility_group_button
    click(UPDATE_FACILITY_GROUP_BUTTON)
  end

  def organization_owner_add_new_facility_group(name, description, unassociated_facility, protocol_name)
    present?(PAGE_HEADING)
    type(FACILITY_NAME, name)
    type(FACILITY_DESCRIPTION, description)
    select_unassociated_facility(unassociated_facility)
    select_protocol_dropdown(protocol_name)
    click(CREATE_FACILITY_GROUP_BUTTON)
  end

  def click_on_associated_facility(name)
    present?(ASSOCIATED_FACILITY_LABEL)
    find(:xpath, "//div[@class='form-check']/label[text()='#{name}']/../input").click
  end
end
