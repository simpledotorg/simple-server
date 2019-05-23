class DashboardPage < ApplicationPage

  ORGANIZATION_NAME = { xpath: "//th/h2" }.freeze

  def get_organization_count
    all_elements(ORGANIZATION_NAME).size
  end
end
