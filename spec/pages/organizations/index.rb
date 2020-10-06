module OrganizationsPage
  class Index < ApplicationPage
    ORGANIZATIONS = {css: "div.org-card"}.freeze

    def get_card_count
      all_elements(CARDS).size
    end
  end
end
