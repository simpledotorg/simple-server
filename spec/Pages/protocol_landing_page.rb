require 'Pages/Base'
class ProtocolLandingPage < Base
  include Capybara::DSL

  ADD_NEW_PROTOCOL = {xpath: "//a[@class='btn btn-sm btn-primary']"}
  PAGE_HEADING = {xpath: "//h1[text()='Protocols']"}
  PROTOCOL_INFO_LIST = {xpath: "//tr/td"}
  PROTOCOL_NAMES = {xpath: "//tr/td/a"}
  COLUMN_NAME = {xpath: "//tr/th"}

  def column_headings
    col_name = ["Name", "Follow up days"]
    elements = all_elements(COLUMN_NAME)
    elements.each {|ele| col_name.each {|name| ele.text.include? name}}
  end

  def column_info(protocol_info)
    column_headings
    all_elements(PROTOCOL_INFO_LIST).each {|lst| protocol_info.each {|info| lst.text.include? info}}
  end

  private :column_headings, :column_info

  def verify_protocol_landing_page(protocol_info)
    present?(PAGE_HEADING)
    present?(PROTOCOL_INFO_LIST)
    column_info(protocol_info)
  end

  def click_add_new_protocol
    click(ADD_NEW_PROTOCOL)
  end

  def click_edit_protocol_link(name)
    find(:xpath, "//td/a[text()='#{name}']/../../td/a[text()='Edit']").click
  end

  def select_protocol(name)
    element = all_elements(PROTOCOL_NAMES)
    element.each {|names| names.click if names.text.include? name}
  end
end