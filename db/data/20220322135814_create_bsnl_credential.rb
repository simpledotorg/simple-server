class CreateBsnlCredential < ActiveRecord::Migration[5.2]
  def up
    Credential.create(name: "BSNL_SMS_JWT", value: "")
  end

  def down
    Credential.find("BSNL_SMS_JWT").delete
  end
end
