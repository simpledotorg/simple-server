# frozen_string_literal: true

module AdminPage
  module Organizations
    class New < ApplicationPage
      ORGANIZATION_NAME_TEXT_FIELD = {id: "organization_name"}.freeze
      ORGANIZATION_DESCRIPTION_TEXT_FIELD = {id: "organization_description"}.freeze
      CREATE_ORGANIZATION_BUTTON = {css: "input.btn-primary"}.freeze

      def create_new_organization(org_name, org_desc)
        type(ORGANIZATION_NAME_TEXT_FIELD, org_name)
        type(ORGANIZATION_DESCRIPTION_TEXT_FIELD, org_desc)
        click(CREATE_ORGANIZATION_BUTTON)
      end
    end
  end
end
