class DashboardPage < ApplicationPage

  ORGANIZATION_NAME = {xpath: "//th/h2"}.freeze
  FACILITY_GROUP_LIST = {xpath: "//td/a"}.freeze
  # #analytic page
  FACILITY_GROUP_NAME = {xpath: "//h1"}.freeze
  FACILITY_LIST = {xpath: "//td/a"}.freeze

  def get_organization_count
    all_elements(ORGANIZATION_NAME).size
  end

  def click_facility_group_link(group_name)
    all_elements = all_elements(FACILITY_GROUP_LIST)
    all_elements.each {|name| name.click if name.text.include? group_name}
    present?(FACILITY_GROUP_NAME)
  end

  def get_facility_count_at_in_analytics_page
    all_elements(FACILITY_LIST).size
  end

  def get_facility_count
    all_elements(FACILITY_GROUP_LIST).size
  end

  def get_organization_count
    all_elements(ORGANIZATION_NAME).size
  end
end
