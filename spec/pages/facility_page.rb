class FacilityPage
  include Capybara::DSL

  FACILITY_PAGE_HEADING={xpath:"//h1[text()='All facilities']"}.freeze
  ADD_FACILITY_GROUP_BUTTON={xpath: "//a[@class,'btn btn-sm btn-primary float-right']"}.freeze
  ORGANISATION_LIST={xpath: '//h1'}.freeze
  NEW_FACILITY={xpath: "//a[text()=' New Facility']"}.freeze

end