module AdminPage
  module Protocols
    class Index < ApplicationPage
      ADD_NEW_PROTOCOL = {css: "a.btn-primary"}.freeze
      CLOSE_BUTTON = {css: "button.close"}.freeze

      def click_add_new_protocol
        click(ADD_NEW_PROTOCOL)
      end

      def click_edit_protocol_link(name)
        within(:xpath, "//div[@id='" + name + "']") do
          find(:css, "a.btn-outline-primary").click
        end
      end

      def select_protocol(name)
        find(:xpath, "//a[text()='" + name + "']").click
      end

      def delete_protocol(name)
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
