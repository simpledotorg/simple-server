# frozen_string_literal: true

module AdminPage
  module Users
    class Edit < ApplicationPage
      PIN = {id: "user_password"}.freeze
      PIN_CONFIRMATION = {id: "user_password_confirmation"}.freeze
      REGISTRATION_FACILTIY_DROPDOWN = {css: "select[name='user[registration_facility_id]']"}.freeze
      UPDATE_USER = {css: "input.btn-primary"}.freeze

      def edit_pin
        type(PIN, "4321")
        type(PIN_CONFIRMATION, "4321")
        click(UPDATE_USER)
      end

      def edit_registration_facility(name)
        find(:xpath, "//select[@name='user[registration_facility_id]']/following-sibling::button").click
        find("ul.dropdown-menu.inner > li", text: name).click
        click(UPDATE_USER)
      end
    end
  end
end
