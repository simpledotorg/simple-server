module OrganizationsPage
  class Index < ApplicationPage
    ORGANIZATIONS = {css: "div.card.organization"}.freeze

    def get_organization_count
      all_elements(ORGANIZATIONS).size
    end
  end
end
