# frozen_string_literal: true

module AdminPage
  module Protocols
    class New < ApplicationPage
      MEDICATION_LIST_NAME = {id: "medication_list_name"}.freeze
      MEDICATION_LIST_FOLLOWUP_DAYS = {id: "medication_list_follow_up_days"}.freeze
      CREATE_MEDICATION_LIST_BUTTON = {css: "input.btn-primary"}.freeze

      def create_new_medication_list(name, followup_days)
        type(MEDICATION_LIST_NAME, name)
        type(MEDICATION_LIST_FOLLOWUP_DAYS, followup_days)
        click(CREATE_MEDICATION_LIST_BUTTON)
      end
    end
  end
end
