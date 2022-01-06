# frozen_string_literal: true

module AdminPage
  module ProtocolDrugs
    class Edit < ApplicationPage
      NAME = {id: "medication_name"}.freeze
      MEDICATION_DOSAGE = {id: "medication_dosage"}.freeze
      RX_NORM_CODE = {id: "medication_rxnorm_code"}.freeze
      UPDATE_MEDICATION_BUTTON = {css: "input.btn-primary"}.freeze
      MEDICATION_LIST_NAME_HEADING = {css: "h1"}.freeze

      def edit_medication_info(dosage, code)
        present?(MEDICATION_LIST_NAME_HEADING)
        type(MEDICATION_DOSAGE, dosage)
        type(RX_NORM_CODE, code)
        click(UPDATE_MEDICATION_BUTTON)

        # assertion
        page.has_content?("Medication was successfully updated")
      end
    end
  end
end
