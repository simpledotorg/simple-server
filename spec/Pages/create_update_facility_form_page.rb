class FacilityFormPage < ApplicationPage
  include Capybara::DSL

  PAGE_HEADING = {xpath: "//h1[text()='New facility']"}.freeze
  NAME_LABEL = {xpath: "//label[text()='Name']"}.freeze
  NAME_EDIT_BOX = {id: "facility_name"}.freeze
  FACILITY_TYPE_LABEL = {xpath: "//label[text()='Facility type']"}.freeze
  FACILITY_TYPE_EDIT_BOX = {id: "facility_type"}.freeze
  STREET_ADDRESS_LABEL = {xpath: "//label[text()='Street address']"}.freeze
  STREET_ADDRESS_EDIT_BOX = {id: "facility_street_address"}.freeze
  VILLAGE_LABEL = {xpath: "//label[text()='Village or colony']"}.freeze
  VILLAGE_EDIT_BOX = {id: "facility_village_or_colony"}.freeze
  DISTRICT_LABEL = {xpath: "//label[text()='District']"}.freeze
  DISTRICT_EDIT_BOX = {id: "facility_district"}.freeze
  STATE_LABEL = {xpath: "//label[text()='State']"}.freeze
  STATE_EDIT_BOX = {id: "facility_state"}.freeze
  COUNTRY_LABEL = {xpath: "//label[text()='Country']"}.freeze
  COUNTRY_EDIT_BOX = {id: "facility_country"}.freeze
  PIN_CODE_LABEL = {xpath: "//label[text()='Pin']"}.freeze
  PIN_CODE_EDIT_BOX = {id: "facility_pin"}.freeze
  LATITUDE_LABEL = {xpath: "//label[text()='Latitude']"}.freeze
  LATITUDE_EDIT_BOX = {id: "facility_latitude"}.freeze
  LONGITUDE_LABEL = {xpath: "//label[text()='Longitude']"}.freeze
  LONGITUDE_EDIT_BOX = {id: "facility_longitude"}.freeze
  CREATE_UPDATE_FACILITY_BUTTON = {xpath: "//input[@class='btn btn-primary']"}.freeze
  EDIT_FACILITY_HEADING = {xpath: "//h1[text()='Edit facility']"}.freeze

  def verify_new_facility_page
    present?(PAGE_HEADING)
    present?(NAME_LABEL)
    present?(NAME_EDIT_BOX)
    present?(FACILITY_TYPE_LABEL)
    present?(FACILITY_TYPE_EDIT_BOX)
    present?(STREET_ADDRESS_LABEL)
    present?(STREET_ADDRESS_EDIT_BOX)
    present?(VILLAGE_LABEL)
    present?(VILLAGE_EDIT_BOX)
    present?(DISTRICT_LABEL)
    present?(DISTRICT_EDIT_BOX)
    present?(STATE_LABEL)
    present?(STATE_EDIT_BOX)
    present?(COUNTRY_LABEL)
    present?(COUNTRY_EDIT_BOX)
    present?(PIN_CODE_LABEL)
    present?(PIN_CODE_EDIT_BOX)
    present?(LATITUDE_LABEL)
    present?(LATITUDE_EDIT_BOX)
    present?(LONGITUDE_LABEL)
    present?(LONGITUDE_EDIT_BOX)
  end

  def create_new_facility(name, type, street, village, district, state, country, pincode, latitude, longitude)
    type(NAME_EDIT_BOX, name)
    type(FACILITY_TYPE_EDIT_BOX, type)
    type(STREET_ADDRESS_EDIT_BOX, street)
    type(VILLAGE_EDIT_BOX, village)
    type(DISTRICT_EDIT_BOX, district)
    type(STATE_EDIT_BOX, state)
    type(COUNTRY_EDIT_BOX, country)
    type(PIN_CODE_EDIT_BOX, pincode)
    type(LATITUDE_EDIT_BOX, latitude)
    type(LONGITUDE_EDIT_BOX, longitude)
    click(CREATE_UPDATE_FACILITY_BUTTON)
  end

  def reset_value()
    present?(EDIT_FACILITY_HEADING)
    clearText(LONGITUDE_EDIT_BOX)
    clearText(LATITUDE_EDIT_BOX)
    click(CREATE_UPDATE_FACILITY_BUTTON)
  end

  def edit_facility(name, type, street, village, district, state, country, pin_code, latitude, longitude)
    present?(EDIT_FACILITY_HEADING)
    type(NAME_EDIT_BOX, name)
    type(FACILITY_TYPE_EDIT_BOX, type)
    type(STREET_ADDRESS_EDIT_BOX, street)
    type(VILLAGE_EDIT_BOX, village)
    type(DISTRICT_EDIT_BOX, district)
    type(STATE_EDIT_BOX, state)
    type(COUNTRY_EDIT_BOX, country)
    type(PIN_CODE_EDIT_BOX, pin_code)
    type(LATITUDE_EDIT_BOX, latitude)
    type(LONGITUDE_EDIT_BOX, longitude)
    click(CREATE_UPDATE_FACILITY_BUTTON)
  end
end