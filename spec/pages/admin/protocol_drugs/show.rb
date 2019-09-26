module AdminPage
  module ProtocolDrugs
    class Show < ApplicationPage
      SUCCESSFUL_MESSAGE = { css: "div.alert-primary" }.freeze
      MESSAGE_CROSS_BUTTON = { css: "button.close"}.freeze
      FOLLOW_UP_DAYS = { xpath: "//div[@class='page-title']/p" }.freeze
      EDIT_PROTOCOL_BUTTON = { xpath: "//a[text()='Edit protocol']" }.freeze
      NEW_PROTOCOL_DRUG_BUTTON = { xpath: "//a[text()='New protocol drug']" }.freeze
      PROTOCOL_DRUG_NAME = { xpath: "//tr/td[1]" }.freeze

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

      def verify_protocol_drug_name_list(drug_name)
        drug_name_list = all_elements(PROTOCOL_DRUG_NAME)
        drug_name_list.each do |name|
          if name.text.include? drug_name
            true
            #need to error exception
          end
        end
      end

      def click_edit_protocol_drug_button(drug_name)
        within(:xpath ,"//h5[text()='#{drug_name}']/../..")do
          find(:css ,"a.btn-outline-primary").click
        end
      end
    end
  end
end
