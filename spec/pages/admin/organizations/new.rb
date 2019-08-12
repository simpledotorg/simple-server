module AdminPage
  module Organizations
    class New < ApplicationPage
      ORGANIZATION_NAME_TEXT_FIELD = { id: 'organization_name' }.freeze
      ORGANIZATION_DESCRIPTION_TEXT_FIELD = { id: 'organization_description' }.freeze
      CREATE_ORGANIZATION_BUTTON = { css: 'input.btn-primary' }.freeze

      def create_new_organization(orgName, orgDesc)
        type(ORGANIZATION_NAME_TEXT_FIELD, orgName)
        type(ORGANIZATION_DESCRIPTION_TEXT_FIELD, orgDesc)
        click(CREATE_ORGANIZATION_BUTTON)
      end
    end
  end
end

