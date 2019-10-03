module AdminPage
  module ProtocolDrugs
    class Edit < ApplicationPage
      NAME = { id: "protocol_drug_name" }.freeze
      PROTOCOL_DRUG_DOSAGE = { id: "protocol_drug_dosage" }.freeze
      RX_NORM_CODE = { id: "protocol_drug_rxnorm_code" }.freeze
      UPDATE_PROTOCOL_BUTTON = { css: "input.btn-primary" }
      PROTOCOL_NAME_HEADING = {css: 'h1' }

      def edit_protocol_drug_info(dosage, code)
        present?(PROTOCOL_NAME_HEADING)
        type(PROTOCOL_DRUG_DOSAGE, dosage)
        type(RX_NORM_CODE, code)
        click(UPDATE_PROTOCOL_BUTTON)

        # assertion
        page.has_content?("Protocol drug was successfully updated.")
      end
    end
  end
end
