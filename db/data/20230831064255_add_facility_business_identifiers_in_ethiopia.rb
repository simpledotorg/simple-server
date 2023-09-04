# frozen_string_literal: true

class AddFacilityBusinessIdentifiersInEthiopia < ActiveRecord::Migration[6.1]
  FACILITY_IDENTIFIERS = {
    "20b9225f-c1be-4585-882f-45f6d8160174" => "HCIjxskLtAy",
    "8e9098a3-ba71-438c-96b8-17a9b85a8feb" => "k0NDQTXTSkD",
    "0ee397aa-66c4-42ea-879c-19378d66cbfa" => "hBM37JUG2mJ",
    "2e722691-b75c-46e1-a960-43eb795a2408" => "iBzxf4Kbomn",
    "3993765b-1ec6-48f4-aa49-bf3203c9cfc7" => "SZoLvBrQ4rJ",
    "7c4eccd9-6b5d-4c54-ad59-e9d72e935462" => "dSLlwKmF6hP",
    "97b674a3-7889-492e-903a-4e913628bebc" => "sBLijW98tkD",
    "27288d0c-73ff-42d9-984c-f85148a0a44c" => "GIrO4Vy5AU8",
    "bbcc461c-09ac-44fe-b73c-c901b4f8a4cc" => "ALUF40kmx0k",
    "03ee63e0-23d7-41ac-bb6b-6820a822c91d" => "DFqaK1s06aC",
    "964770a0-7aaf-4d02-a86f-6473ba24b1d6" => "VbxruN1Qud4",
    "fd829b96-230b-49d6-bace-e8c681efc7f2" => "D3YsCDJJV3f",
    "4d36cd24-9c7d-4b59-8114-6e179d7558c2" => "PRmadb9LUkC",
    "809070d4-516b-40a1-a0f1-b57da6fc4111" => "Aln4kXsGqm6",
    "ef922a65-a17d-4dd1-8e3e-7e84dc3f95ce" => "PyRFvVFInUy",
    "d26039c0-f460-4730-be0d-4d24f0ff7211" => "mTaEXyho4hI",
    "7a547e62-51d7-484e-9ee7-9409536d679c" => "akldvkz12wT",
    "459976d1-69eb-467e-bb02-f84c0356caaa" => "oQRrDCxoZNT",
    "4ddd74f2-bd94-47b9-a39a-e2d7d1b27ee5" => "FWqNP8smQho",
    "32536ed9-18e9-4234-aa69-44f791eea507" => "EKSkKprzUb2",
    "306b241a-cca0-4282-b45a-24fcd3758994" => "jvEMiU9tMLe",
    "fc909093-3177-41bc-88c0-5a636cd20692" => "FiMrBwl0oo0",
    "16aa6415-b610-43b8-bc21-25ace9abdfa8" => "diYWpTHZtCw",
    "e26426d1-936a-4045-92f3-eccb293e8967" => "KBfiDXWjETn",
    "90fc661a-fdf6-4cf1-8431-4f9b5ad92502" => "tTZX2hxzyRR",
    "1c0a392d-a298-42ae-9731-4bf47f40f12d" => "sbHC7FgFWLb",
    "e852a982-a813-44a1-b9dd-1219ed8bcdb9" => "RuhWkurzxXy",
    "d0f1ed68-20d5-4dae-9a52-f5faf7a6def4" => "XidDZoPPqj6",
    "8306b482-8bbe-46a7-becb-1d47db7bbc06" => "XGRbsdt9xsE",
    "2b55c98d-1380-4a23-8ac7-bbe7c16d3544" => "C8HFOWHlarl",
    "413e915f-47e6-4379-a5fc-be3fad393e06" => "htGs3ST4c55",
    "3e22120c-360b-4ad6-82f0-2960349c62e8" => "ut2BTKG9j7E",
    "742ace6e-e86d-4a78-b1df-c9d4f0c21e9c" => "KuTv8c1gqLv",
    "28be1b5f-9a77-4e85-800d-7a1f5f061b11" => "vdWDpmjXiod",
    "2b70df68-4cfe-4767-9234-cc85fa13a927" => "uUFu8MmC1N2",
    "1b5ed107-8bfd-42b6-bc23-2664f6f781ab" => "ijWbyhFFCx3",
    "2bed45c4-8dc7-40f8-8b49-3653a5cbab6b" => "mXy5MKakCXX",
    "b9a30acc-a243-46a4-accc-afeeb4b96784" => "O1gFRqSqBpY",
    "d1d0be81-3b9c-42e5-ac40-876153e8c74e" => "MEJYJtqSqlT",
    "cd1f179b-8276-45a8-9fac-1bc9dd71ba30" => "SOw1j01Dk2d",
    "e10d28b2-204f-40e8-b252-3cce8444f558" => "hASDJs1l7Uc",
    "ab10cef1-1742-4305-86e5-5e3a904bd62b" => "MUnfwQryhZ5",
    "e5a9bdc1-7302-4e34-b067-283ebde08469" => "SK7FGJGfOt2",
    "67bbe898-5224-4b46-adeb-dddf72456808" => "qn8ptV5Prqb",
    "b8337ca6-5f1a-4528-9845-def772e84a7c" => "SDyh2spIBU3",
    "f7e4cb80-bd35-4248-87fb-532c88a69468" => "eNwpyeo0BOT",
    "43db12e2-e14c-446f-b5f4-be6ef4ddf951" => "Vcof25JT4PJ",
    "0c015f80-bf09-4b21-98f4-274990e21a86" => "BKVCeW4q361",
    "2d1ea6f4-37bb-4850-a5db-b0bada9781fc" => "DKsubMyV5Nd",
    "cab61ca6-50c3-4a49-9071-ca21d7a56c7c" => "EhFRIiSwwgx",
    "d2ed8ddd-8f4c-4dd1-8f7b-4e9151daba81" => "EjT3LKUyale",
    "f8284384-7d27-4f03-b855-c5eac4116454" => "g3Sz2VRqAo7",
    "28208165-f462-4602-ad63-c39d59979556" => "QAVjKCqVAXA",
    "e8a4d9c8-5ec0-498f-a5b2-353550f895c4" => "mez1nztRYbc",
    "28582cac-da41-4ae8-9cf7-73577b0ac1df" => "n9oGQflGqnT",
    "209e38d3-8cd4-4b03-98bf-63589895c699" => "d7xLvXrmM24"
  }

  def up
    unless CountryConfig.current_country?("Ethiopia") && ENV["SIMPLE_SERVER_ENV"] == "production"
      print "This migrations is meant to run only in Ethiopia production"
      return
    end

    FACILITY_IDENTIFIERS.each do |simple_id, dhis2_org_id|
      facility = Facility.find_by(id: simple_id)
      unless facility.present?
        print "Facility not found: id #{simple_id}"
        next
      end

      facility.business_identifiers.find_or_create_by(
        identifier_type: :dhis2_org_unit_id,
        identifier: dhis2_org_id
      )
    end
  end

  def down
    unless CountryConfig.current_country?("Ethiopia") && ENV["SIMPLE_SERVER_ENV"] == "production"
      print "This migrations is meant to run only in Ethiopia production"
      return
    end

    FACILITY_IDENTIFIERS.each do |simple_id, dhis2_org_id|
      facility = Facility.find_by(id: simple_id)
      unless facility.present?
        print "Facility not found: id #{simple_id}"
        next
      end

      facility.business_identifiers.find_by(
        identifier_type: :dhis2_org_unit_id,
        identifier: dhis2_org_id
      ).delete
    end
  end
end
