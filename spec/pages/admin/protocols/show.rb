module AdminPage
  module Protocols
    class Show < ApplicationPage
      SUCCESSFUL_MESSAGE = { css: 'div.alert-primary' }.freeze
      MESSAGE_CROSS_BUTTON = { css: 'button.close' }.freeze
      FOLLOW_UP_DAYS = { id: 'Follow up days' }.freeze
      EDIT_PROTOCOL_BUTTON = { id: 'Edit protocol' }.freeze
      NEW_PROTOCOL_DRUG_BUTTON = { id: 'New protocol drug' }.freeze
      PROTOCOL_DRUG_NAME = { id: 'drug_name' }.freeze

      def verify_successful_message(message)
        verify_text(SUCCESSFUL_MESSAGE, message)
        present?(EDIT_PROTOCOL_BUTTON)
        present?(NEW_PROTOCOL_DRUG_BUTTON)
        present?(FOLLOW_UP_DAYS)
      end

      def verify_updated_followup_days(days)
        verify_text(FOLLOW_UP_DAYS, days)
      end

      def click_message_cross_button
        click(MESSAGE_CROSS_BUTTON)
        not_present?(SUCCESSFUL_MESSAGE)
      end

      def click_edit_protocol_button
        click(EDIT_PROTOCOL_BUTTON)
      end

      def click_new_protocol_drug_button
        click(NEW_PROTOCOL_DRUG_BUTTON)
      end

      def click_edit_protocol_drug_button(drug_name)
        within(:xpath, "//div[@name='" + drug_name + "']") do
          find(:css, 'a.btn-outline-primary').click
        end
      end

      def delete_protocol_drug(protocol_name)
        within(:xpath, "//div[@name='" + protocol_name + "']") do
          page.accept_alert do
            find('a.btn-outline-danger').click
          end
        end

        # assertion
        page.has_no_content?(protocol_name)
        page.has_content?('Protocol was successfully deleted.')
      end
    end
  end
end
