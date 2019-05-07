require 'Pages/Base'
class ProtocolDetailPage < Base
  include Capybara::DSL

  SUCCESSFUL_MESSAGE = {xpath: "//div[@class='alert alert-primary alert-dismissable fade show']"}.freeze
  MESSAGE_CROSS_BUTTON = {xpath: "//div[contains(@class,'alert')]//span"}.freeze
  FOLLOW_UP_DAYS = {xpath: "//div[@class='page-title']/p"}.freeze
  EDIT_PROTOCOL_BUTTON = {xpath: "//a[text()='Edit protocol']"}.freeze
  NEW_PROTOCOL_DRUG_BUTTON = {xpath: "//a[text()='New protocol drug']"}.freeze
  PROTOCOL_DRUG_NAME = {xpath: "//tr/td[1]"}.freeze

  def verify_successful_message(message)
    verifyText(SUCCESSFUL_MESSAGE,message)
    present?(EDIT_PROTOCOL_BUTTON)
    present?(NEW_PROTOCOL_DRUG_BUTTON)
    present?(FOLLOW_UP_DAYS)
  end

  def verify_updated_followup_days(days)
    verifyText(FOLLOW_UP_DAYS,days)

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

  def verify_protocol_drug_name_list(drug_name)
    drug_name_list = all_elements(PROTOCOL_DRUG_NAME)
    drug_name_list.each do |name|
      if name.text.include? drug_name
        true
        #need to error exception
      end
    end
  end

  def click_edit_protocol_drug_button(drug_name)
    find(:xpath , "//td[text()='#{drug_name}']/../td/a[text()='Edit']").click
  end
end









