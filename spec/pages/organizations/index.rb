module OrganizationsPage
  class Index < ApplicationPage
    CARDS = {css: "div.card"}.freeze

    def get_card_count
      all_elements(CARDS).size
    end
  end
end
