require 'Pages/base'
class UsersRegisteredFacilityPage < Base
  include Capybara::DSL

  FACILITY_NAME = {xpath: "//small/a"}
  ADDRESS_HEADING = {xpath: "//h2[text()='Address']"}
  ADDRESS = {xpath: "//p"}
  EDIT_FACILITY_BUTTON = {xpath: "//a[@class='btn btn-sm btn-primary']"}

  def verify_registered_facility_landing_page
    present?(FACILITY_NAME)
    present?(ADDRESS_HEADING)
    present?(ADDRESS)
    present?(EDIT_FACILITY_BUTTON)
  end
end
