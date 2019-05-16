require 'Pages/Base'
class ProtocolDetailPage < Base
  include Capybara::DSL

  SUCCESSFUL_MESSAGE = {xpath: "//div[@class='alert alert-primary alert-dismissable fade show']"}.freeze
  MESSAGE_CROSS_BUTTON = {xpath: "//div[contains(@class,'alert')]//span"}.freeze
  FOLLOW_UP_DAYS = {xpath: "//div[@class='page-title']/p"}.freeze
  EDIT_PROTOCOL_BUTTON = {xpath: "//a[text()='Edit protocol']"}.freeze
  NEW_PROTOCOL_DRUG_BUTTON = {xpath: "//a[text()='New protocol drug']"}.freeze
  PROTOCOL_DRUG_INFO = {xpath: "//tr/td"}.freeze

  PROTOCOL_NAME = {xpath: "//div[@class='page-title']/h1"}
  COLUMN_NAME = {xpath: "//th"}

  def verify_successful_message(message)
    verifyText(SUCCESSFUL_MESSAGE, message)
    present?(EDIT_PROTOCOL_BUTTON)
    present?(NEW_PROTOCOL_DRUG_BUTTON)
    present?(FOLLOW_UP_DAYS)
  end

  def verify_updated_followup_days(days)
    verifyText(FOLLOW_UP_DAYS, days)
  end

  def click_message_cross_button
    click(MESSAGE_CROSS_BUTTON)
    not_present?(SUCCESSFUL_MESSAGE)
  end

  def click_edit_protocol_button
    click(EDIT_PROTOCOL_BUTTON)
  end

  def click_new_protocol_drug_button
    click(NEW_PROTOCOL_DRUG_BUTTON)
  end

  def click_edit_protocol_drug_button(drug_name)
    find(:xpath, "//td[text()='#{drug_name}']/../td/a[text()='Edit']").click
  end

  def column_name
    columns = ["Protocol drugs", "Dosage", "RxNorm code"]
    all_elements(COLUMN_NAME).each {|element| columns.each {|name| element.text.include? name}}
  end
  private :column_name

  def verify_protocol_detail_page(name, days)
    verifyText(PROTOCOL_NAME, name)
    verifyText(FOLLOW_UP_DAYS, days)
    present?(NEW_PROTOCOL_DRUG_BUTTON)
    column_names
  end

  def verify_protocol_drug_info(drug_info)
    all_elements(PROTOCOL_DRUG_INFO).each {|element| drug_info.each {|info| element.text.include?info}}
  end
end









