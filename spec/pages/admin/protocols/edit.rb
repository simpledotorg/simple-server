module AdminPage
  module Protocols
    class Edit < ApplicationPage
      PROTOCOL_NAME = {id: "protocol_name"}.freeze
      PROTOCOL_FOLLOWUP_DAYS = {id: "protocol_follow_up_days"}.freeze
      UPDATE_PROTOCOL_BUTTON = {css: "input.btn-primary"}.freeze

      def update_protocol_followup_days(followup_days)
        type(PROTOCOL_FOLLOWUP_DAYS, followup_days)
        click(UPDATE_PROTOCOL_BUTTON)
      end

      def update_protocol_name(name)
        type(PROTOCOL_NAME, name)
        click(UPDATE_PROTOCOL_BUTTON)
      end
    end
  end
end
