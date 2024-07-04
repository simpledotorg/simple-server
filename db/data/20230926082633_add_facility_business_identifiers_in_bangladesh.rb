# frozen_string_literal: true

class AddFacilityBusinessIdentifiersInBangladesh < ActiveRecord::Migration[6.1]
  FACILITY_IDENTIFIERS = {
    "78e32150-81d9-44d0-b1d1-cd6c02b36b30" => "Rgl8l1h0Wsg",
    "db9c5cff-026e-4458-9835-d56054bd4a96" => "J3YsRt42XCt",
    "dc55f49c-bf32-4636-9f10-a2bc7a7e3c19" => "vMuxhcSFZim",
    "7b9766a5-6227-4a86-8714-6e682d0a003c" => "nej7NVUo4Pl",
    "2dac0744-7fd6-4e89-b257-48a57f414a96" => "eVcVNuLVolm",
    "81f44ab1-5084-4d64-a60d-840283c1ef37" => "K8XTTmlhbMp",
    "785f8082-262f-4713-8588-172099812eee" => "ZebGJlNOh5G",
    "b012eba0-251a-4d74-a1f6-ff2acc241d4d" => "wXqcI3gOmdX",
    "001df055-c3e3-480a-aea5-613eb8d8b322" => "djzPWedvYtC",
    "1c574efb-1bc6-4de5-856e-44fb0edefc8d" => "AMvEzJnrbM8",
    "65b04b6a-dddf-4f73-807f-7881a73fe8cd" => "kiZzpCrbcN8",
    "a152ba51-6b6f-4b05-b741-63052b702814" => "j8TMihNGISq",
    "e9e94efd-15f3-45c5-b7a2-643a90124aca" => "bC76lR6wkAf",
    "f8d427c5-d938-46e3-bd3b-1700534e9f51" => "BiD42dNFdGC",
    "3c014418-747c-4162-b046-3be347d37e13" => "gzMk9FdamGc",
    "824f4ba3-63d0-407d-95dd-75426953bb3b" => "e28x6JJohsD",
    "a255b9c2-4c9b-4324-8c68-00f6af712ab0" => "v0rBWuflbzq",
    "568614c7-6ace-4660-8fdb-0a6f68fa0ee7" => "avjeKn8gNCR",
    "eadbefff-488f-4d1a-911f-56deeb57646b" => "Ac19Xmijk00",
    "c8aba9f2-28b6-4d11-b80a-94db597fb3d2" => "QejIwvIo9ad",
    "5190c94f-5b69-454c-93e3-b596b43418cf" => "unXqOMcVS2i",
    "23f9d9ea-4605-4e14-b9d3-bc061bc285a7" => "nRm6mKjJsaE",
    "222b8a05-b8c9-4aa9-bd28-40c41beab72f" => "xYw4Cfu26k5",
    "c4652196-cafa-45c2-8de8-621c20cabc74" => "lZFKqRdYtVa",
    "c8c80c45-027b-4f67-9091-c8c9e35c5acb" => "vdaFqs5bWGy",
    "78f3aacf-6e13-4c2e-a365-2afaabeff3e7" => "DipzbxMF001",
    "347424bb-2414-4843-aac6-83165ec113a0" => "CtvAFFnPPuh",
    "f2513f7e-ee48-40f7-a803-6313bb2f1d52" => "pQkOF7g22C0",
    "664a3faa-442e-428e-85d5-85e99f32d083" => "DbwpQW1MRRQ",
    "0b47b70c-c857-4fe6-ae10-8d1487e400dd" => "ujYEDMrYIVd",
    "761b0942-4749-4e5a-81ba-74193604d385" => "ILDAljvoQbX",
    "9193370f-318d-42e0-909a-dd536db8ced4" => "mWVquHaC63G",
    "c087839b-d99e-4a21-83f6-b86aa8ce40ca" => "lcNe4chLWPQ",
    "97c57734-f8bf-4d29-bb0c-4d466e4201a5" => "u53oyfaJbLb",
    "26aaa264-3c1c-4468-9b4d-13d5eac626e5" => "LmelV5MN0bf",
    "599e9a86-df6c-453e-9a3c-956ec4247b9f" => "fo9FjniZ2UT",
    "15e3e52c-f12d-4ca1-8881-31e56ff40d94" => "huXGxzFuzW3",
    "4d106d32-b20c-4448-9d35-55e9b7fcb01b" => "EOVN9vbYQwy",
    "66467d81-ba30-4b88-b649-4c55657c1ada" => "gDzklYf9Tvc",
    "8e0d27fc-c8f2-427b-8d67-c4d36b6ec07a" => "Lr6vMJMbOJZ",
    "7b490e96-c353-4a51-89e1-32098351530b" => "B0WvJrP8h59",
    "e6fd4cdd-9c6d-427b-9efb-5aab4dd4564a" => "mvs3OmQoWSq",
    "911eb2f2-efd5-4b07-84c8-52b18b8f5f2e" => "NWCExI5PsgP",
    "9221192a-c96c-4d2c-bbfb-3af70e9a0d71" => "DB9Bz6Jv6tG",
    "d78612a1-a0b6-4d8d-a83d-92318354fe77" => "yZ76bNY5rO4",
    "7440dd78-f600-4973-ad93-ec68b6b514c9" => "RtKPVau2B3X",
    "27f8ac98-46c8-470e-a0ba-262066a65ac1" => "pEYrXd4eY8I",
    "93d55268-981a-4824-a1ab-e461fe53f7d5" => "Uue4brUYKtD",
    "dc8e43d3-62b2-410e-b83f-dbfeccc892f6" => "YbYQfQejXbZ",
    "1ad8d39e-7211-4d1e-a119-12505d786f49" => "fuhHnTGs04s",
    "66a1277e-69e9-4aa6-bce2-9522e96e9c22" => "LSHGzVNvHPy",
    "7e5b8513-b4e8-40e8-ad0c-6c375dfeb426" => "nxJA3zeL9HC",
    "37abba71-7137-40f5-8260-4bb8586a783e" => "sUGf1JvNqmW",
    "6b98204e-d4cf-4f20-bdcf-7b6242bb00ec" => "XnrEWOapPsx",
    "4d2a1706-f71b-4753-9d4a-8ff8598ac7bc" => "Xd3We6j67rM",
    "06933831-78cd-4af0-b790-0b044855e9ab" => "GyN0El1KEqB",
    "a04e118c-9011-4501-8c96-42105945f4a9" => "B0ZBDQBaz77",
    "8884ca00-43fd-4542-bc62-81d74b6fd83f" => "X07MeS8j3Qz",
    "4573023a-3c82-45d4-9b11-aa512b7d6299" => "uiVATamu4Vr",
    "7a2b8081-b5c8-4e2c-a277-03aa63911d65" => "PAahyK4wIkn",
    "3f8f9889-da8a-425a-9e4d-8d8a4a9628c6" => "E81fUDeEAA9",
    "99fac759-8088-4d7c-b2ab-9fdcc72236aa" => "mvkLKmwEwvJ",
    "6a360ed5-8eea-4d00-a61d-e1c18ff0789b" => "w9RQasavZ5x",
    "e30d223f-2da3-490f-b1bd-715cf807f5d9" => "UikxxQ8C5gP",
    "96d6cc2c-72ec-4794-becb-1965da461e1c" => "hJOzD4T3nCG",
    "950754d4-185f-4317-bf6b-e177caee19f0" => "pdIrUmvohRk",
    "d34c1232-2286-406e-836b-fdd63b3858a6" => "ZtfDWyRJbWG",
    "a67110f0-afe0-4c3e-a79e-db4849903d89" => "vA9eUPrkbji",
    "07abe284-1974-4a6a-9d12-519c79d1b357" => "roxIQscs96F",
    "e4b00f74-4854-44e5-8d51-f18a0afce2ab" => "CYGrOmxSbVq",
    "8b9a1504-909e-4476-99c8-27ba3da35ae1" => "ABDYRR00inN",
    "0cb68351-1daf-4b52-9b7a-de1d63128c3d" => "wOoE4rfPt8v",
    "7d26913b-217f-4d47-9e4c-410c6a21ea8b" => "vCSZKgFa9P7",
    "80338e5e-6308-48ea-a1db-246bddbde632" => "er95ZfTrewt",
    "b2e9b9db-2e9a-4716-875b-77f8e729ca79" => "m05ztaqI6MZ",
    "b2b72592-e515-4519-ba21-ad48288a4ebc" => "hZbUf1KEnFa",
    "f160efdc-4e9b-421e-8823-6841babbdf48" => "zTcglzzN7qb",
    "25952a9c-d564-4257-8dcc-47c2db8c9952" => "AguNDiwPVr5",
    "1b4d9ac7-c2e6-462f-b655-88f45486e6c6" => "ufEHHE6KHQ9",
    "23741786-8b5e-4e30-89ed-018a3f76c089" => "ohPFkkUn1fN",
    "39d1ba19-210b-4371-bbc2-7306e13a0785" => "clbPOREnrYB",
    "c818c23e-5a83-4a87-9c67-ba8a68a290c7" => "nctQMqSgx69",
    "3a2328be-83d5-474a-8229-4493b32fb1fa" => "qOoOQ9gTa6W",
    "9e736ddb-2dd7-49cf-a3d8-dc14ca194ca3" => "saxX7Emz3zP",
    "62186a59-e21f-4a51-a74f-0b562cbb656a" => "E8mFTbtDylz",
    "df85a7e7-1662-4043-8150-2a084f44e9d4" => "VM1a3eK3xv0",
    "6b8f04a1-7e46-468a-99e3-a4649db7f576" => "HhbI2DkfemY",
    "44bad633-0683-4619-a70e-3182c608e9d0" => "IIOJvOTSDoI",
    "dc770854-6257-4ddb-bdae-90a832ed014f" => "cccYoxgp3Tb",
    "35b90121-fdd1-4550-8938-bbd13929423c" => "smSDJ3L9enP",
    "c58df02d-f7b3-4220-9d89-85e476377f98" => "iGeRFevvykV",
    "03eb0359-83af-4db8-95fa-ba4117d8c111" => "SfBTWdhw5ex",
    "a8de724e-7d85-4b46-ac63-f365f451540f" => "f8lw2nDY3UV",
    "d83cb3b6-2193-4416-a61f-565c181e4910" => "B4wN3aLX03z",
    "87715d0f-0128-449c-9d27-78cbc00c61e3" => "d653LrZbDTL",
    "498ca9c1-79b7-4611-b061-71330d3b15e6" => "skgVMbiQ8AO",
    "f0407b6b-1bbf-4f2e-b708-db76601d8d96" => "N1bqzF8pttt",
    "35c52ad2-2f46-416b-a0a6-2c8bd4ffc671" => "lD6qoMevWvK",
    "564d73f6-3281-49af-b110-0b8ba2da2fd7" => "cF78zaczo4W",
    "9691df3e-43a7-46a3-bead-b2931f3a0738" => "qF2KvBP35mt",
    "256e87af-ea02-4b45-9a5d-720b9decc34e" => "BSjKdql0qAr",
    "5e97c8d0-bdba-4970-b762-4c037085d7e4" => "JSbdnCha8jn",
    "f66dd36e-f076-4b33-9d95-901d7886e8e5" => "snzItXjt0Os",
    "a4279216-f288-42b5-8508-fda7c102b10a" => "mV9Fu5U2WJd",
    "09618255-7ce8-4eec-a1fc-2d7ea31f31c1" => "RdnNMJ5AeOb",
    "4f085e02-8264-422b-bcf9-93ca9aaa0f54" => "UKrUt5wT4gi",
    "fcf1595f-2919-44e8-b7ba-c34b2b2b8dde" => "bPlGk16odGE",
    "6a1222fc-fe87-441f-9198-86b2557001f1" => "lGjIJ7DmKvv",
    "aa8c648d-7c92-4244-b808-a4bba4707d8d" => "jlv761KyVXi",
    "9e5dd85b-a5b8-4456-b945-9e5e74b6777f" => "Z2PYPGlSZfN",
    "b305f9a9-9215-4726-8d10-df9e16754b2d" => "E4jyE914Ta6",
    "b4407e88-2a5b-4b40-a5eb-a4dabcbe2c4c" => "CtPDOixr9Kn",
    "3a77da12-ae5a-4e85-bd6b-d2bfb9a93e02" => "UA7ZqzRUjnC",
    "8d1c9744-ace5-4693-9a64-bc4d2fba88b4" => "pTcgulCxBqz",
    "49d0b4bf-97d1-4ee8-9ab5-799fa37aafd9" => "UtGEBzCbTnB",
    "02bee5b6-888c-486c-a04b-96aa769a3b0a" => "TRgMmKlyLCS",
    "6f4209ae-7c77-4722-b14a-de838df3591d" => "d81hfS4DWxM",
    "db3df65d-5885-4af2-a453-2b400ef88587" => "OAUEGwPxeRY",
    "d30c8a20-e8a4-4f4a-b62b-a30a99abacbe" => "WqYIHyIqaGm",
    "9205872d-251e-45f6-aaac-5f275e6863e2" => "XtYUREXRlUr",
    "345a48e3-a22c-4f6c-ac0b-b05c6fc3083e" => "us1B2l5ErYR",
    "c0b955ec-e964-4829-9d7e-ed4468109676" => "OelgvH46MSu",
    "706a85e2-b2dd-4588-9c3e-eef674e8cf61" => "CejwC6EalgZ"
  }

  def up
    unless CountryConfig.current_country?("Bangladesh") && ENV["SIMPLE_SERVER_ENV"] == "production"
      print "This migrations is meant to run only in Bangladesh production"
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
    unless CountryConfig.current_country?("Bangladesh") && ENV["SIMPLE_SERVER_ENV"] == "production"
      print "This migrations is meant to run only in Bangladesh production"
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
