module AdminPage
  module Protocols
    class New < ApplicationPage
      PROTOCOL_NAME = {id: "protocol_name"}.freeze
      PROTOCOL_FOLLOWUP_DAYS = {id: "protocol_follow_up_days"}.freeze
      CREATE_PROTOCOL_BUTTON = {css: "input.btn-primary"}.freeze

      def create_new_protocol(name, followup_days)
        type(PROTOCOL_NAME, name)
        type(PROTOCOL_FOLLOWUP_DAYS, followup_days)
        click(CREATE_PROTOCOL_BUTTON)
      end
    end
  end
end
