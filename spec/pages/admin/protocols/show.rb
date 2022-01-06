# frozen_string_literal: true

module AdminPage
  module Protocols
    class Show < ApplicationPage
      SUCCESSFUL_MESSAGE = {css: "div.alert-primary"}.freeze
      MESSAGE_CROSS_BUTTON = {css: "button.close"}.freeze
      FOLLOW_UP_DAYS = {id: "Follow up days"}.freeze
      EDIT_MEDICATION_LIST_BUTTON = {id: "Edit medication list"}.freeze
      NEW_MEDICATION_BUTTON = {id: "Add medication"}.freeze
      PROTOCOL_DRUG_NAME = {id: "drug_name"}.freeze

      def verify_successful_message(message)
        verify_text(SUCCESSFUL_MESSAGE, message)
        present?(EDIT_MEDICATION_LIST_BUTTON)
        present?(NEW_MEDICATION_BUTTON)
        present?(FOLLOW_UP_DAYS)
      end

      def verify_updated_followup_days(days)
        verify_text(FOLLOW_UP_DAYS, days)
      end

      def click_message_cross_button
        click(MESSAGE_CROSS_BUTTON)
        not_present?(SUCCESSFUL_MESSAGE)
      end

      def click_edit_medication_list_button
        click(EDIT_MEDICATION_LIST_BUTTON)
      end

      def click_new_medication_button
        click(NEW_MEDICATION_BUTTON)
      end

      def click_edit_medication_button(medication_name)
        within(:xpath, "//div[@name='" + medication_name + "']") do
          find(:css, "a.btn-outline-primary").click
        end
      end

      def delete_medication(medication_list_name)
        within(:xpath, "//div[@name='" + medication_list_name + "']") do
          page.accept_alert do
            find("a.btn-outline-danger").click
          end
        end

        # assertion
        page.has_no_content?(medication_list_name)
        page.has_content?("Medication list was successfully deleted")
      end
    end
  end
end
