# frozen_string_literal: true

module AdminPage
  module ProtocolDrugs
    class New < ApplicationPage
      NAME = {id: "medication_name"}.freeze
      MEDICATION_DOSAGE = {id: "medication_dosage"}.freeze
      RX_NORM_CODE = {id: "medication_rxnorm_code"}.freeze
      CREATE_MEDICATION_BUTTON = {css: "input.btn-primary"}.freeze
      MEDICATION_NAME_HEADING = {css: "h1"}.freeze

      def add_new_medication(name, dosage, code)
        type(NAME, name)
        type(MEDICATION_DOSAGE, dosage)
        type(RX_NORM_CODE, code)
        click(CREATE_MEDICATION_BUTTON)
      end
    end
  end
end
