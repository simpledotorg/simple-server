require 'Pages/base'
class FacilityDetailPage < Base

  SUCCESSFUL_MESSAGE = {xpath: "//div[@class='alert alert-primary alert-dismissable fade show']"}
  CROSS_BUTTON = {xpath: "//button[@class='close']"}

  FACILITY_GROUP_NAME = {xpath: "//h1//a"}
  FACILITY_NAME = {xpath: "//h1//br"}
  ADDRESS_LABEL = {xpath: "//h2[text()='Address']"}
  COLUMN_HEADER = {xpath: "//tr/th"}
  USERS_LABEL = {xpath: "//h2[text()='Users']"}
  EDIT_FACILITY_BUTTON = {xpath: "//a[@class='btn btn-sm btn-primary']"}
  LATITUDE_LONGITUDE_LABEL = {xpath: "//h3"}

  USER_LIST = {xpath: "//tbody/tr"}

  def address

  end

  def latitude_longitude

  end

  def user_info
  end

  def table_headers
    columns = ["Name", "Sync status", "Status reason", "Phone number", "Last login"]
    all_elements = all_elements(COLUMN_HEADER)
    all_elements.each { |header| columns.each { |name|  header.text.equal? name}}
  end
  private :address, :latitude_longitude, :user_info, :table_headers

  def verify_facility_detail_page
    present?(SUCCESSFUL_MESSAGE)
    present?(CROSS_BUTTON)
    present?(USERS_LABEL)
    table_headers
  end

  def click_edit_facility_button
    click(EDIT_FACILITY_BUTTON)
  end

  def click_on_edit_button_for_user(name)
    find(:xpath, "//td/a[text()='#{name}']/../../td/a[text()='Edit']").click
  end

  def get_total_users_at_facility_detail_page
    all_elements(USER_LIST).size
  end
end