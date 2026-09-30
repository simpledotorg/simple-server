# frozen_string_literal: true

class AddPartnerFacilityDhis2Mappings < ActiveRecord::Migration[6.1]
  FACILITY_IDENTIFIERS = {
    "a7162922-9b46-4d0a-b0ec-d30faaad08cc" => "G5DmQ0UY3vd",
    "bf9dd8fe-c2c5-4653-b589-248897045971" => "kOOtq7woqzE",
    "496f6e9d-b8d4-442e-9907-fa572621964c" => "gU1zKbsvtvX",
    "5fb213d3-f1b3-4a50-b6f0-f9a53d7a84eb" => "ZpyRE4dbqyC",
    "c661f1e8-2faa-4c33-94ca-777df03a4d9a" => "zvAJ7NDJG1X",
    "3c218c87-0d29-46b3-b51c-88c876cf491c" => "LPBFgrCnvOd",
    "ee8843a5-3dac-45ef-8a99-fc10af039ce8" => "UqMnBWWlgp6",
    "8ac5e9e2-695b-4e09-a7ac-e66e295406e5" => "G2dZyu8d0eD",
    "b66fdcc1-f8ea-4328-aa9f-dfeeafb005d2" => "oTpHyv0FZN3",
    "6f8a7867-c55c-4f9c-8d0f-2aa57ccd9826" => "nuyFfSqOON1",
    "8c6840c6-9ce8-4e01-82ee-1b8af00675a2" => "M2nBljfCy0Y",
    "9de02909-8fe7-4863-8bde-531a841e1017" => "tLkbJv6ceLT",
    "5af1c7d5-1118-4e61-a8bb-c4af32b655fb" => "z02xpgvBshU",
    "f9ccc420-a05b-46a5-bf8e-84470965e0ca" => "vpWVWzuO7BE",
    "08352c84-7a9d-423a-8dd2-576b78c3afce" => "W0Rjb7e0EFd",
    "713f4707-2f05-455b-a689-ed5741c25558" => "obRVWw9Q8YS",
    "03839538-6881-4692-8851-d2336da11988" => "H3NCGKQfZTF",
    "2bbd7517-4b00-4858-a04f-618eddcbc95a" => "iMjCtzgEkX0",
    "cae3eeee-ff85-4c94-b7f0-37680a687f34" => "cVXQfTBqjvb",
    "7b709761-fbb2-4b29-9cd0-ed6e3fb5c653" => "yic2ZO5ms3B",
    "f45cf849-7255-46c9-b8b8-b66e8792ee91" => "DPzO1SBnOvB",
    "fd0974f4-be6a-44e9-9c78-243765fef30d" => "sY5IJFDYW2a",
    "19f1bfe7-c558-4094-84b0-9767d24dcf2f" => "URDYAKVE5uV",
    "a8fc1a80-a632-4d3e-92d6-f49386f372bf" => "yy1KbXMOGjR",
    "dd82094a-0241-4bcb-94bd-6209a7af6785" => "qESjeNZvXHe",
    "2e4d8a5d-c625-4e2b-be28-d60ba1506b71" => "d3vUFOo6OLa",
    "06ef7048-420c-4a53-82f3-ffaaaa5fe66b" => "NmLrJzgJ33I",
    "6661e08d-ba06-4f0c-8b4a-284f6b202fd4" => "noC43js09U8",
    "39946904-67c4-4259-8802-3dd6eb01ae0e" => "yqz7NXENkLY",
    "fdd3f459-9631-4dee-a587-c113de01958d" => "gPSi9Um7hh8",
    "f247f4b6-d561-4c3f-a83f-aeaa4ce5bafb" => "izQmCamWsGi",
    "bc7f5a5a-e4e8-4fbf-988a-221db74712f4" => "CjNSDwn4T4I",
    "1e6af4b2-9d04-45c1-906a-a6f3bcb6533e" => "MGiZ0FfNqca",
    "061659dc-c9fe-429c-b50f-80e13156f6cd" => "D71mFdbvYFg",
    "0d51ed5d-4bce-40e1-9fa3-9d5f808716de" => "oPTIP4xpMuS",
    "57a16ff6-b837-473c-a36d-87770a1e344a" => "cjeWloXdfoV",
    "87687166-6a27-4763-96bf-e6aa2852d2b0" => "Ytab3eVnzky",
    "715656ed-64ea-4ddb-8bd1-182252089e59" => "Vk70Hcg8BwZ",
    "e5bb1fee-8fd6-44f3-aff3-5f8f0743d0e8" => "GlWEW2dRLaG",
    "501b85fa-a150-49fd-ae2d-cfe0e59470ad" => "rdZG3R48pEt",
    "8207fda1-a37b-4c19-be25-6056c47e374b" => "XYEUyYM3vJs",
    "745eb0bc-2ea1-408e-bdfb-700978782e98" => "NbK2vAyLd1Z",
    "29d782af-e6aa-4bf1-8fb3-d70cf50f2bdd" => "AN5Q60BAPuN",
    "8444f538-d76e-4d04-84a0-ac8c36a1d927" => "nf4zMqXlt9V",
    "95fefbb3-0921-4ffe-82b0-2394957cc362" => "ovGW0GsUs0a",
    "87f067b0-d352-4fc8-b941-8f7ff9101be6" => "to5qkWx1Pq1",
    "d80e24ae-8004-4a31-baf1-a54469afe9c1" => "g8hTnoxTJi7",
    "93e4cca1-8615-427e-a6a0-f4cf80c4a7fe" => "rBCsx1NWhpn",
    "eece1ac9-6b56-412f-8a1e-bc3a3d86fc9b" => "bKEvNbSYBz5",
    "783cb3d7-2f0c-417f-81e7-9262f444ee4c" => "NEk7Nd4of9L",
    "70c21fc2-7f31-48d4-83d6-663e8e0ca12f" => "OkigMruGF9O",
    "f1b360d9-4ed9-4dfd-b9b7-721dcb827513" => "TpNRXDwYE0k",
    "fbbfcd2d-54cb-4a80-9281-30a29c065d1e" => "phh66QLDubK",
    "ce44f573-6622-4856-b0d3-7c068e6b86ef" => "NcXwiKKpGyK",
    "1568731d-798c-4521-84dc-738d6fd92658" => "irNCIGO8rPT",
    "0e2fd6ea-b5a8-4ec7-a280-a525596afe56" => "zNPpFhOSXRj",
    "72c47ef4-2747-4900-b9ad-f3cec2f455ac" => "VHad0oCcloL",
    "c8b3ac51-eaf1-413d-9b4d-816e648b7f73" => "j7pX6C8Q7VP",
    "d545c1cd-984c-4e71-a8b3-745c6353ea9d" => "NoYbX4bltrb",
    "75bdedd2-ca3a-483a-a81c-9f923d723489" => "ywPCIF2tQc3",
    "fdb34f45-923c-4612-aa15-3f8b6cc3175f" => "XbUezY5JRDV",
    "d2ac9d18-10e7-455d-a9a1-3b4b7326afc3" => "wiCxSdLnFFd",
    "ca2689cc-fc16-45b1-8cad-896d10203f31" => "qsoEdkSyYzG",
    "9a3ffca4-5e9e-4d87-b60f-1de7d06e7f06" => "DsHhmyvbdt8",
    "93e53f59-8183-4690-9a67-fb156afae7eb" => "mlphw7kLYxe",
    "680049a1-efb8-4247-b781-882f5deaf6fc" => "OtAl339rBrM",
    "3a43db20-b9f6-461b-b0ed-d75b5515dbef" => "LrAlGhIdyvw",
    "2436a177-fb88-42c6-acb9-41dc2a56b5f5" => "S4ZyN0FOwR1",
    "3f5135c1-9138-4ada-8d3b-351bd623d191" => "A0qQKAt9OHW",
    "59ef717a-8f9b-4dd8-ba28-9614f66152ba" => "O67YdyoZSam",
    "80a443c0-fec0-4185-a55f-4f0685b43988" => "eG2hRjzkxUx",
    "ad5b8e38-6968-4661-a605-d0e7b5dd9912" => "lF3pqVwXeyt",
    "8a34af23-f0a4-46e1-8932-4b390b0bee64" => "ubJBf4W5Uiq",
    "05d4ee21-b0be-493f-96b1-1a42df4f1912" => "jCPzcC62WqU",
    "1c52fe1a-0e70-40cc-a3cf-6d542d999087" => "OTMMgp9YABl",
    "1178e17a-0b6c-4711-aa21-55b041273bf2" => "TrR4tvWkjfO",
    "7cda7b45-902a-413f-8d57-cd1a73ce101b" => "Sqpei9gbXVm",
    "ba4894c4-b12e-4aba-b827-7a82c9f67eed" => "ECDcOOXoOJY",
    "d599a830-9d4d-434a-b239-4e369c155a07" => "Pfw1f43EYjI",
    "3e3205c2-ccc4-42d4-9af2-c312ae4fefad" => "oRRzJYuieOw",
    "b971fc80-bb82-48db-9501-04ec9efc8017" => "KjCU9q9XztH",
    "c090e814-e7f8-4975-af9e-eaa0beda1e49" => "xNeSsWcYDpv",
    "14e64494-3cfc-4a62-82a5-c4d06c54e0ef" => "Oq9onfWy7Mq",
    "262a0f45-ba02-49cd-abb3-dc8d49a43016" => "RwAbsV7JvBV",
    "0505dc27-1686-4392-84f0-4b9bde371574" => "DW1XcsetHJD",
    "3274ec93-b165-4848-9ce8-dfe764de8ee3" => "f7XnCO8bvVI",
    "1334789b-0591-44a1-8e58-84a056174e87" => "Rb1nPeL0ImA",
    "0abe6c18-c66a-4581-a35a-3305bf8f7dfc" => "Wel6Iabxh2z",
    "19d5a65e-f132-459b-a985-4170722baeba" => "oZGe7vj3gOI",
    "f472c5db-188f-4563-9bc7-9f86a6ed6403" => "ZSTFF1Mqzvg",
    "12165d0c-dbaa-4ee8-a479-dee3c28356a7" => "k0CiGrwlSx7",
    "1c74b01e-6245-45e7-8e55-ac48b21ea4e8" => "hHhA6uJbxYQ",
    "3265eee0-d287-4408-8998-60a977d2db61" => "VuqxaCL6d9w",
    "50e6a724-9187-4883-bbfb-8401c1c2b5ee" => "FogtRlvyln2",
    "d6bf07a4-8548-4419-ad7c-d400b7fe5560" => "iPWDg6NvW0T",
    "99388326-c131-4117-a81a-a42cf5a5203a" => "UUkgZ9WitxL",
    "c2b8242e-de07-4aec-aa99-932d88e8432c" => "ahOq4MlrDog",
    "72223c93-25c3-459e-b318-b79ba612bf75" => "Nf1zzx5Kfnk",
    "3e86dd46-43e8-4cbf-b6bf-837084b8b5cb" => "C9Dw0lKOS9U",
    "75a5b4a7-9d3b-45ab-a02d-22153456fb08" => "ZbO1FbO9azt"
  }

  def up
    unless CountryConfig.current_country?("Bangladesh") && ENV["SIMPLE_SERVER_ENV"] == "production"
      puts "This migration is meant to run only in Bangladesh production"
      return
    end

    FACILITY_IDENTIFIERS.each do |simple_id, dhis2_org_id|
      facility = Facility.find_by(id: simple_id)
      unless facility.present?
        puts "Facility not found: id #{simple_id}"
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
      puts "This migration is meant to run only in Bangladesh production"
      return
    end

    FACILITY_IDENTIFIERS.each do |simple_id, dhis2_org_id|
      facility = Facility.find_by(id: simple_id)
      unless facility.present?
        puts "Facility not found: id #{simple_id}"
        next
      end

      identifier = facility.business_identifiers.find_by(
        identifier_type: :dhis2_org_unit_id,
        identifier: dhis2_org_id
      )
      identifier&.delete
    end
  end
end
