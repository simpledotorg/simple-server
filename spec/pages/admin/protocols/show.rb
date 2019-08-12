module AdminPage
  module Protocols
    class Show < ApplicationPage
      ADD_NEW_PROTOCOL = { css: "a.btn-primary" }

      def click_add_new_protocol
        click(ADD_NEW_PROTOCOL)
      end

      def click_edit_protocol_link(name)
        within(:xpath, "//a[text()='#{name}']/../../..") do
          find(:css, "a.btn-outline-primary").click
        end
      end

      def select_protocol(name)
        find(:xpath, "//a[text()='#{name}']").click
      end
    end
  end
end
