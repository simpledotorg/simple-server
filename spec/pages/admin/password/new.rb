# frozen_string_literal: true

module AdminPage
  module Passwords
    class New < ApplicationPage
      RESET_PASSWORD_BUTTON = {css: "div.text-right>input"}.freeze
      MESSAGE = {css: "div.alert-primary"}.freeze
      MESSAGE_CROSS_BUTTON = {css: "button.close"}.freeze
      LOGIN = {css: "a[href='/email_authentications/sign_in']"}.freeze
      EMAIL_TEXT_BOX = {id: "email_authentication_email"}.freeze
      UNLOCK_INSTRUCTION_LINK = {css: "a[href='/email_authentications/unlock/new']"}.freeze

      def do_reset_password(email)
        type(EMAIL_TEXT_BOX, email)
        click(RESET_PASSWORD_BUTTON)
        present?(MESSAGE)
        click(MESSAGE_CROSS_BUTTON)
        not_present?(MESSAGE)
      end

      def click_login_link
        click(LOGIN)
      end

      def assert_forgot_password_landing_page
        present?(EMAIL_TEXT_BOX)
        present?(RESET_PASSWORD_BUTTON)
        present?(LOGIN)
      end

      def click_on_unlock_instruction_link
        click(UNLOCK_INSTRUCTION_LINK)
      end
    end
  end
end
