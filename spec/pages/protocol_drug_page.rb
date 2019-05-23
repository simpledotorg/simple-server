class ProtocolDrugPage < ApplicationPage

  NAME = { id: "protocol_drug_name" }.freeze
  PROTOCOL_DRUG_DOSAGE = { id: "protocol_drug_dosage" }.freeze
  RX_NORM_CODE = { id: "protocol_drug_rxnorm_code" }.freeze
  CREATE_PROTOCOL_BUTTON = { xpath: "//input[@class='btn btn-primary']" }
  UPDATE_PROTOCOL_BUTTON = { xpath: "//input[@class='btn btn-primary']" }
  EDIT_PROTOCOL_DRUG_TEXT = { xpath: "//h3" }
  PROTOCOL_NAME_HEADING = { xpath: "//h1" }

  def add_new_protocol_drug(name, dosage, code)
    type(NAME, name)
    type(PROTOCOL_DRUG_DOSAGE, dosage)
    type(RX_NORM_CODE, code)
    click(CREATE_PROTOCOL_BUTTON)
  end

  def edit_protocol_drug_info(dosage, code)
    present?(PROTOCOL_NAME_HEADING)
    present?(EDIT_PROTOCOL_DRUG_TEXT)
    type(PROTOCOL_DRUG_DOSAGE, dosage)
    type(RX_NORM_CODE, code)
    click(UPDATE_PROTOCOL_BUTTON)
  end
end