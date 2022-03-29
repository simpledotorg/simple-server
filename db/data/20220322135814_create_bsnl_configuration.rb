class CreateBsnlConfiguration < ActiveRecord::Migration[5.2]
  require "rake"

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    rake = Rake.application
    rake.init
    rake.add_import "lib/tasks/bsnl.rake"
    rake.load_rakefile

    Configuration.create(name: "bsnl_sms_jwt", value: "jwt")
    rake["bsnl:refresh_sms_jwt"].invoke
  end

  def down
    Configuration.find_by(name: "bsnl_sms_jwt")&.delete
  end
end
