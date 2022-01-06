# frozen_string_literal: true

module AdminPage
  module Protocols
    class Edit < ApplicationPage
      MEDICATION_LIST_NAME = {id: "medication_list_name"}.freeze
      MEDICATION_LIST_FOLLOWUP_DAYS = {id: "medication_list_follow_up_days"}.freeze
      UPDATE_MEDICATION_LIST_BUTTON = {css: "input.btn-primary"}.freeze

      def update_medication_list_followup_days(followup_days)
        type(MEDICATION_LIST_FOLLOWUP_DAYS, followup_days)
        click(UPDATE_MEDICATION_LIST_BUTTON)
      end

      def update_medication_list_name(name)
        type(MEDICATION_LIST_NAME, name)
        click(UPDATE_MEDICATION_LIST_BUTTON)
      end
    end
  end
end
