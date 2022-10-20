class AddCphcUserToCphcFacilityMapping < ActiveRecord::Migration[6.1]
  def change
    add_column :cphc_facility_mappings, :encrypted_cphc_auth_token, :text
    add_column :cphc_facility_mappings, :cphc_user_details, :json
  end
end
