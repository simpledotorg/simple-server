class CreateBsnlCredential < ActiveRecord::Migration[5.2]
  require 'rake'

  def up
    rake = Rake.application
    rake.init
    rake.add_import 'lib/tasks/refresh_bsnl_sms_jwt.rake'
    rake.load_rakefile

    Credential.create(name: "BSNL_SMS_JWT", value: "")
    rake['bsnl:refresh_sms_jwt'].invoke()
  end

  def down
    Credential.find("BSNL_SMS_JWT").delete
  end
end
