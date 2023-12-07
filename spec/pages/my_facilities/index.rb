module MyFacilitiesPage
  class Index < ApplicationPage
    SEARCH_BAR = {id: "search_query"}

    def search_region(query)
      type(SEARCH_BAR, query)
    end
  end
end
