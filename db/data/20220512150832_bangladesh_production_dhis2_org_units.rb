class BangladeshProductionDhis2OrgUnits < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.transaction do
      if CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
        facility_org_unit_map = {
          "8bf07061-0681-4224-af29-f265baaf6437" => "fvfwpzISCWN",
          "58a7fedb-5c59-4e7c-a47e-a8942fc890f9" => "EM9kLDReivm",
          "cc48e39e-52a1-4450-ace3-1718c75da3e1" => "TRrdKanxnGU",
          "092ff349-0415-4c1c-be36-fef793395b64" => "agHVh94H3fZ",
          "4e796653-804f-43fd-88d7-f9fdf94a656e" => "z2S4M7ZqPwT",
          "89037841-2fd2-4f6e-9a6c-95414e37716e" => "coF7aBLFUNA",
          "7f9f004a-39b9-418f-9099-5fb6ff3989b0" => "Xa2syB0sJZA",
          "5cbe8cb2-a152-4c46-aacb-45e06946a247" => "hcgXRBYjnOT",
          "3d9e19a2-8a57-4248-98fe-e90967806f27" => "ZrGrRL9HAW6",
          "68603a37-175d-4f11-bd30-85fc6c4c3a38" => "Jig2LPxXVBZ",
          "edaf3ebd-3dbd-48c3-9911-875ad1356f5d" => "h4kXTKwbr0K",
          "0419482c-d09f-4afd-9b96-29ec9f851bb5" => "TtfmUEZrc8O",
          "daff41a3-4922-41b0-a822-6fef2db07e68" => "da8BXojbpb2",
          "16da3a6f-4dff-4d90-a990-39e2e4ea17da" => "CLabDgvXbrP",
          "f2430802-6f63-4349-9b7d-3b9be21e7f20" => "QnpNVN5fa8W",
          "8a6c5634-c739-4b29-98a2-362f4852bf5d" => "Ps7ivpiyPWX",
          "4fb55980-be47-4b9b-9bed-641ec1ebca63" => "RQMUx14Q3KN",
          "861280d6-2460-4670-8619-69df19e68901" => "IVvhOtl7e7P",
          "e8bb3ffe-f703-4ebb-bb74-411254a67a61" => "RrZIRBKmRvU",
          "f7395a98-09ed-4507-acb9-6a1d93f4af9b" => "sbbhoQOEAzq",
          "e9060f47-2119-4839-8ad0-7f13fb46bccb" => "BFG0daPnPt2",
          "e11402ef-a574-4d15-9b06-d2dd134e7d8a" => "gnRsOMPxW65",
          "032152aa-8152-488e-8681-729d22b8a228" => "jn8L9D40tpG",
          "cc98c651-ce8b-4019-be6b-012f52d0cb21" => "LE1EtZCcoPj",
          "2e7a4917-be56-4d2e-aee6-4c9738ab8a9b" => "Zx6aOKefr88",
          "42bb7742-0d2a-4149-9d33-922af47605df" => "zLeRigzvYNQ",
          "f06b37f7-02e9-48d9-9eb3-cf756dc30daa" => "nWSAOooBKCc",
          "16bce5e0-cf0f-45a8-b0e1-948abe15c8a7" => "SqeJgSsBREb",
          "9af10f6a-384a-4979-8bc2-dd1b16190668" => "e5VEheg8DkJ",
          "9288b1d9-bdfd-4fdc-baaf-d0761d48a909" => "QIvysBdhxiO",
          "f6020029-e39f-44c8-a791-e27e103185f7" => "CkQVDf4C6Dn",
          "834f8368-989c-4487-8f11-9204265699b8" => "aSYhooLoJht",
          "76ba80a8-617d-46d9-b373-c12e25d19980" => "OXxdYvPq5IR",
          "8cac9785-0a7b-4cbf-b626-725f936d3884" => "cM9llybGhva",
          "b589428c-16cf-4cb4-a7c0-1ae4a9aa7ab8" => "q81LWOUAD0F",
          "a77c92db-1cbb-4d7a-93bf-f884d771cc40" => "x42UVY3FWoJ",
          "5ff2d76d-9f73-4264-a791-524f13d78dc2" => "E5hqvNwg1Ah",
          "5d770b3c-6450-45ab-950b-d276e8e7835f" => "ZKKrUl1tUqU",
          "00db147c-5289-40b4-bd3c-090cac07c9ea" => "Ejir7Rt3hSj",
          "f01ebd45-6781-40c5-88e9-738a89eddf51" => "eX9DjHRJ8DX",
          "b4fa254d-c899-4268-951f-82f1312bae98" => "cXlFwLNU4Tz",
          "da8ea97f-6fb5-41c3-ac46-f47e44946076" => "zrjSLQjVgl2",
          "5d4bd491-1c78-42c1-b62e-4df43bf02065" => "fOWBhFPm5OM",
          "6fb9d5dd-47c9-4d65-9179-58a4424ce6a1" => "KIT0A4L3uwP",
          "1f37710e-978d-46e5-85e5-abf63e563d2e" => "EKNkAXZV8rJ",
          "130be963-f38e-4c58-b671-69b71949dfbd" => "N5oM6oNXZnY",
          "52190202-4c2c-4a8f-975c-2ca2c13584e2" => "LY9ezqrak3p",
          "736925da-ae87-4b61-ba5f-45e0e217559b" => "ck6ziiZh6Aq",
          "b22cfc80-9880-4fdf-9c89-5113240063ab" => "TMa1wTDrzbU",
          "5f49a91c-1eed-4d3f-926c-3b644c40f7c3" => "lScJRHgaq9E",
          "0fad3822-9f5a-46ea-b02f-90501a184252" => "GZqXU7oTsjz",
          "42f121f2-86fc-42e4-b8bb-aa48d493ddae" => "kA6xAnUHAkH",
          "f5c42150-7933-40b8-9163-30e2a023c3f8" => "sA4sDPFafoJ",
          "cab5fa8a-850c-42f2-88f6-834a6d3de5c9" => "ghVtt3Pc4K6",
          "cbd2880c-d3bc-4e7e-bc04-e21a492e3e50" => "VhCAYVuA1N6"
        }

        FacilityBusinessIdentifier.with_discarded.destroy_all
        facility_org_unit_map.each do |facility_id, org_unit_id|
          FacilityBusinessIdentifier.create!(
            identifier_type: "dhis2_org_unit_id",
            identifier: org_unit_id,
            facility_id: facility_id
          )
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
