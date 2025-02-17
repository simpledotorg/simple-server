module AdminPage
  module Facilities
    class New < ApplicationPage
      TELECONSULTATION_CHECKBOX = {id: "facility_enable_teleconsultation"}
      USER_SEARCH_BOX = {id: "search_query"}

      def enable_teleconsultation
        check(TELECONSULTATION_CHECKBOX)
      end

      def search_user(search_query)
        type(USER_SEARCH_BOX, search_query)
      end
    end
  end
end
