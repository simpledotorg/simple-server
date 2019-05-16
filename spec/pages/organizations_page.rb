require 'Pages/Base'
class OrganizationsPage < Base

  include Capybara::DSL

  ADD_NEW_ORGANIZATION_BUTTON = {xpath: "//a[@class='btn btn-sm btn-primary']"}.freeze
  ORGANIZATION_NAME_TEXT_FIELD = {id: 'organization_name'}.freeze
  ORGANIZATION_DESCRIPTION_TEXT_FIELD = {id: 'organization_description'}.freeze
  CREATE_ORGANIZATION_BUTTON = {xpath: "//input[@class='btn btn-primary']"}.freeze
  COLUMN_INFO_LIST = {xpath: "//tr/td"}.freeze
  PAGE_HEADING = {xpath: "//h1[text()='Organizations']"}
  COLUMN_HEADINGS = {xpath: "//tr/th"}

  def column_headings
    column_name = ["Name", "Description", "Facility Groups", "Facilities", "Users"]
    all_elements(COLUMN_HEADINGS).each {|element| column_name.each {|name| element.text.include? name}}
  end

  def column_info(org_info)
    column_headings
    all_elements(COLUMN_INFO_LIST).each {|element| org_info.each {|info| element.text.include? info}}
  end

  private :column_headings, :column_info

  def verify_organization_info(org_info)
    present?(PAGE_HEADING)
    column_info(org_info)
  end

  def create_new_organization(orgName, orgDesc)
    click(ADD_NEW_ORGANIZATION_BUTTON)
    type(ORGANIZATION_NAME_TEXT_FIELD, orgName)
    type(ORGANIZATION_DESCRIPTION_TEXT_FIELD, orgDesc)
    click(CREATE_ORGANIZATION_BUTTON)
  end
end