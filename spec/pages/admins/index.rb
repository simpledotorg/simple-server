module AdminsPages
  class Index < ApplicationPage

    ADD_NEW_ADMIN_BUTTON = {css: "a.btn-primary"}.freeze
    ADMIN_LIST = {css: "div.card"}.freeze
    ERROR_MESSAGE ={css: "div.show"}.freeze

    def click_add_new_Admin_button
      click(ADD_NEW_ADMIN_BUTTON)
    end

    def get_error_message_text
      ERROR_MESSAGE
    end

    def select_admin_card(email)
      within(:xpath,"//div[@title='#{email}']") do
        find(:xpath,"//*[text()='#{email}']").click
      end
    end
  end
end
