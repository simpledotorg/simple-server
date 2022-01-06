# frozen_string_literal: true

module AdminPage
  module Protocols
    class Index < ApplicationPage
      ADD_NEW_MEDICATION_LIST = {css: "a.btn-success"}.freeze
      CLOSE_BUTTON = {css: "button.close"}.freeze

      def click_add_new_medication_list
        click(ADD_NEW_MEDICATION_LIST)
      end

      def click_edit_medication_list_link(name)
        within(:xpath, "//div[@id='" + name + "']") do
          find(:css, "a.btn-outline-primary").click
        end
      end

      def select_medication_list(name)
        find(:xpath, "//a[text()='" + name + "']").click
      end

      def delete_medication_list(name)
        within(:xpath, "//div[@id='" + name + "']") do
          page.accept_alert do
            find("a.btn-outline-danger").click
          end
        end
        # assertion
        page.has_no_content?(name)
        page.has_content?("Protocol was successfully deleted.")
      end

      def click_on_message_close_button
        click(CLOSE_BUTTON)
        page.has_no_content?("Protocol was successfully deleted.")
      end
    end
  end
end
