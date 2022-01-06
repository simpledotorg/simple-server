# frozen_string_literal: true

module OrganizationsPage
  class Index < ApplicationPage
    ORGANIZATIONS = {css: "div.card"}.freeze

    def get_organization_count
      all_elements(ORGANIZATIONS).size
    end
  end
end
