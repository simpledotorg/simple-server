class DashboardPage < ApplicationPage

  ORGANIZATION_NAME = { css: "div.card" }.freeze

  def get_organization_count
    all_elements(ORGANIZATION_NAME).size
  end
end
