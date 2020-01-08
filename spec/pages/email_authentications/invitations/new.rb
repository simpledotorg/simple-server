module Email_authentications
  module Invitation
    class New < ApplicationPage

      FULL_NAME_EDIT_TEXT_BOX = {css: "#full_name"}.freeze
      EMAIL_EDIT_TEXT_BOX = {css: "#email"}.freeze
      ROLE_EDIT_TEXT_BOX = {css: "#role"}.freeze
      FACILITY_GROUP = {css: 'input#name-input'}.freeze
      # INVITE_ADMIN_BUTTON = {xpath: "//*[text()='Invite Admin']"}.freeze
      INVITE_ADMIN_BUTTON = {css: "button[type='submit']"}.freeze
      DONE_BUTTON = {xpath: "//*[text()='Done']"}.freeze


      ACCESS_TO_ALL_FACILITY = {css: "button.btn-outline-success"}.freeze

      def select_organization(org)
        find(:xpath, "//label[text()='#{org}']/../input").click
      end

      def select_facility(facility_group)
        click(FACILITY_GROUP)
        page.has_content?("Select Faciltiy groups")
        click(ACCESS_TO_ALL_FACILITY)
        click(DONE_BUTTON)
      end

      def select_access_level(access)

        find(:xpath, "//select[@id='access-input']").find(:option, access).select_option
      end

      def select_custom_permission(permission)
        find(:xpath, "//input[@id='#{permission}']").click
      end

      def fill_in_full_name(full_name)
        type(FULL_NAME_EDIT_TEXT_BOX, full_name)
      end

      def fill_in_email(email)
        type(EMAIL_EDIT_TEXT_BOX, email)
      end

      def fill_in_role(role)
        type(ROLE_EDIT_TEXT_BOX, role)
      end

      def click_invite_admin_button
        click(INVITE_ADMIN_BUTTON)
      end
    end
  end
end

