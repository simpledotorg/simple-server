# frozen_string_literal: true

module AdminPage
  module Organizations
    class Index < ApplicationPage
      ADD_NEW_ORGANIZATION_BUTTON = {css: "nav.page-nav>a"}.freeze
      ORGANIZATION_NAME = {css: "div.card"}.freeze

      def is_organization_name_present(expected_org_name)
        org_name = all_elements(ORGANIZATION_NAME)
        org_name.each do |name|
          name.text.include? expected_org_name
        end
      end

      def delete_organization(org_name)
        within(:xpath, "//a[text()='#{org_name}']/../../..") do
          find(:css, "i.fa-trash-alt").click
        end
      end

      def click_on_add_organization_button
        click(ADD_NEW_ORGANIZATION_BUTTON)
      end
    end
  end
end
