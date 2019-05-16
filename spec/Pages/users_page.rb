class UsersPage < ApplicationPage

  PAGE_HEADING = {xpath: "//h1"}
  DISTRICT_LIST = {xpath: "//h2"}
  Users_LIST = {xpath: "//tbody/tr"}

  def all_district
    all_elements(DISTRICT_LIST)
  end

  def all_user
    all_elements(Users_LIST)
  end

  def table_heading
    headings = ["Name", "Sync status", "Status reason", "Phone number", "Registered at facility"]
    elements = all_elements(COLUMN_HEADING)
    headings.each do |col|
      elements.each do |ele|
        ele.text.include? col
      end
    end
  end

  private :all_district, :all_user, :table_heading

  def click_edit_link(user_name)
    find(:xpath, "//td/a[text()='#{user_name}']/../../td/a[text()='Edit']").click
  end

  def click_registered_facility_link(user_name)
    find(:xpath, "//td/a[text()='#{user_name}']/../../td[5]/a").click
  end

  def get_district_count
    all_district.size
  end

  def get_users_count
    all_user.size
  end

  def verify_users_landing_page
    present?(PAGE_HEADING)
    verifyText(PAGE_HEADING, "Users")
    all_district.size != 0
    table_heading
  end

  def select_user(name)
    user_lst = all_elements(Users_LIST)
    user_lst.each {|usr_name| usr_name.click if usr_name.text.include? name}
  end
end
