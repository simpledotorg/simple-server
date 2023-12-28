# frozen_string_literal: true

class SetUpSmsRemindersIndiaJanJun2024 < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 20000
  REGION_FILTERS = {
    "states" => {"include" => ["West Bengal", "Nagaland", "Tamil Nadu", "Maharashtra"]},
    "blocks" => {"exclude" => %w[965c0445-0ec2-41e8-b66a-a32f6efcc56d 6599d33c-c4e9-4f92-af85-1823a028c03a c6baa6e9-bd98-400e-beeb-86d0c6c088a9 9d6789c2-a852-4187-9140-e69a8f2b09df 39ca467d-e3fe-4417-97ab-4f9d98bbe34d 273cd619-6f6a-4651-85b7-b3fb1a8f03ec db6c2a8d-631d-46c3-aa3c-2921854026c1 ab48fa53-8f89-4ee8-9731-330aa36cd992 69657066-f9e9-423e-b443-0d6485fe4487 ef6cea2d-d5fc-42f1-a041-0dadf9280bd1 758f76e4-95d1-4647-856a-66f62d86f6b7 81bdf757-9d5f-4181-ad74-e92a13e3293a ad3b021a-7a00-4846-a196-adf61644891e 3ca02c0b-1f63-43b3-802b-adfd4f074142 461e0f85-5819-4e47-a8d0-c5f10da553d9 48687ea1-851a-4f0a-b8b9-7bfb89a68452 a043b5e3-8a26-465b-a772-ae51801f53f7 6068f3f9-e289-4c4e-bac4-c0f6ed187388 4a0fff60-f074-4f5d-85fc-ab7655a3eee5 eb4c2a50-62db-480f-9be0-7b0f97fcbfaf 5d146dc3-16d0-4c4a-9de1-2df5b0dd1ecd 6d5e3315-3d60-41ba-aaa4-bec6e1b40d1e cfdf9110-6835-4514-ba55-e94894a93205 6331bd3f-9b99-4cf9-8a9d-30bfb2af22d3 5c12c20b-9a76-49e0-a9e8-7716b809bd55 eba33f32-6e48-4795-a6ed-55def1078415 06d1fc05-2c6d-4ba8-9de8-61a633df4aff db3c3073-3260-4198-82ab-34ebd29a0b33 d799127e-3738-43eb-b2db-7b41ccd643e8 54b6ca03-a57b-4e2f-b07e-275f04920f95 52450b30-6960-43b3-ba89-6ed6d34a8593 830484c5-abe8-4bee-a8c7-6b4d752d3024 2d94fa08-2b4e-4cf0-9d34-d42ae12d78fb f3f4275a-5788-4856-afd2-9a892fd185bb 7c6f1a8d-0bb6-475b-913a-37cb0d0d93aa ef87852c-0342-481a-bea1-7f9fe3f42f42 bad8dc03-bcc6-49ff-8689-d1c1fda749a3 f718283a-52c0-4969-ae6d-44ad2b890ab3 7932ee98-641e-4d3d-9f6d-4214a856c901 dc8c794c-02ff-452f-bf5d-94323302a343 0a9dd645-dcac-453b-98bb-fc2de2cffb4a bd64453d-0bd5-4897-9dbe-28b022efd234 8ed92598-4182-452f-9844-25a8f2a82ac8 8de4386c-5582-49ba-bfb6-e1a8cff3e8ab e11cc17a-cf00-4a62-81d2-418afa43f3b2 2f3e0e31-a993-4622-92f1-19db26f1ee4d e15d7bfa-b801-4b7c-b593-e047b9c7eeea 2bb104c5-d504-48a9-8909-6d46c7e48092 41a09735-84df-499b-9369-4dffc8cbb76a 3d2966a0-5476-444a-93cf-3387767970de 79b5ab5b-533d-4be7-b681-1c303dd150a2 9271777e-bfb9-4d93-a01f-3d37f3927bc3 a0bca47a-9e19-4691-9efb-755b81d4e8c7 8b677b2c-0d53-4770-840f-9818af575706 f7a1370a-288f-42d6-bbd6-d3884a77ffb0 4eaa2550-bc33-4a8c-aead-e476d0a3bf79 180a8f57-c8cb-4208-832a-cb429f9d9452 362a32d2-3018-4723-a2d4-8e622976b314 1b5bd472-bf48-4b16-86d8-5070b85f0160 15441a00-3a4f-4245-950f-649de995c6b8 daeaea47-b352-4f8b-823c-33b149c3188c e05986c4-a76b-4b86-8341-ecc2777d89bf 29c12064-4569-4eb1-81c6-e997859bb001 0236a21b-96a0-4d49-86bd-baa87e1620a4 15a1d699-943b-48f8-bb19-166b69bba953 6077516c-d1e3-4cc7-abb5-62fa8121992b 094fb16b-a012-4931-b68e-ac4b8aa7a922 ead96917-f28e-492c-a4f4-b1142b9b9fe5 b758a4c0-ba2b-4bfc-ac62-71fa68c05f59 49ba4066-fc61-475f-bd27-a89b2d2d2f2f 5c914033-d89a-4afa-93da-cc223389e6b8 c1decd73-6013-4a60-b2fe-291c578e97ba 01ee68c9-8a60-46ee-b874-fee5a9e79182 f14383fb-b890-4c6b-bc05-30dea349fc6a eff88eec-abb4-45ba-b667-858afe960b8c 889b9bf5-ba9a-4283-8ef4-36b9ad33c1ad 2028763d-7445-4dba-971e-0e8f7d61441e 8ec44e95-f939-4fb7-9275-cfb96c4e5816 8fd1e480-d5ef-407a-a1c3-b819070c48af e45520c7-2837-4349-9212-bc50cc0ab739 11baa6b7-1351-4710-ab94-01691d12d06c c2562a44-cca1-4f6a-bd87-067ea40b73f2 d59be528-0f13-4f2b-b90e-bf912532da56 0fb8795a-24de-4d8a-b9dd-e473e216d08e 76134ec8-2f5d-4ace-87ea-2b4715cb72c6 b1275ed5-5c3f-4a69-af0c-e9b8c796936b 2cf51c91-27ba-4404-acdf-479d97b3ae3a a4946e66-d703-40d3-8634-656bc7fbc1af 452e733a-fc4d-4847-8594-e68acdc16aa5 86cf25b1-bbf0-46b7-9ac0-2d1699b52615 f299da5b-c26a-4517-8729-bcbbe67728a8 7961fc0a-afe0-43e3-b847-3d643a1cfef5 6983d32f-d4f2-45dc-a604-2ca181e7284e 302f8eb2-224f-4b9c-9b27-21b23b0ac754 358d6aaf-779b-4fa7-a88c-2bda6d7fcdc4 734fb75f-25f5-4608-93b8-e8ab4091a1a3 30cb862b-1002-4562-a9b9-3910ee85acb0 6f09afd5-d878-448b-8d2a-ac0799f40900 230b8bf1-54f9-49ac-98e1-7843dab21819 1e5f5ee9-251e-4e68-a9da-b02fbbef0902 b7ac47c4-db73-4a79-9753-ff2c70a77449 b10be628-29d4-4ccb-a711-38e590ecf03c 91f7817b-f73c-47cf-a8fb-c38280b0be65 e5fcdedc-bb28-4389-be94-286eca535724 3491ff9f-7931-4dff-bea6-22250db6a20d e9566b33-252e-453f-86ad-02d53626041c 1667cd1e-cdef-4387-b418-f9516c34c9f6 e51abd8b-3be3-43db-a86f-0197954263f3 0fff0a31-7450-4e31-8e9f-b1ca858d661d c2b81545-0138-4014-8694-82e570f4ee66 abfb46c0-b8dd-40fe-aa7a-0ed693aad928 cf455f76-0bc0-4f59-b2be-c628de2b85c0 39731fe9-f13a-4370-a148-0968e73ccd16 42ca44b1-2fe8-49d3-af66-33bc2c36763f 8ba7d5df-5e36-4db9-a02c-ad410a6e6e31 90e846bb-d2f7-489f-b758-c5b5fdae3f70 f6395338-4ecb-468c-9a72-d1b5b8e1169e 12077f18-82ff-4d24-abb6-f968f4ae31d2 7b3e5865-dfdd-42c6-ac79-bf1570669591 70ecb380-93b1-4dc0-9aa3-bbebf3df30be 5d652b3f-29db-4e80-b82e-8d690aa16d9f e56e32a6-822a-44c8-aba5-2d066ef9c84b c953f71f-fca9-4456-ac16-a363cafef035 b3c2e413-d9df-49a6-afa0-2bbc4610e884 91be7a95-4dec-4f0d-b2e9-5ddb87f05a6a bf97c3a0-fa91-4b66-857a-374083dcc271 dc0d57ce-239c-4ea0-b3a2-c5aadf683cb1 86bbbcd2-7142-4378-8078-8d101be8932c 0d7e42ac-b4ed-4c24-bfc9-5211ded7a9f0 795048aa-4d6c-49b4-abef-4e73c1a2aecf 9c1f3013-1347-4adb-b027-cfd642d2e20a 5309ff56-7c53-4e7d-9939-d25e2cd2018d dadd4cb6-dc42-4f12-8c3c-c4fa1c8fd46d 7435afbf-28bf-432f-9624-fda905b837c8 4da7d239-b439-4003-9a3f-a242dd4db856 ef6fbb8d-e4b5-4844-a7e3-8627e9328df5 f1dc8d43-4da9-4378-a1f4-a52dbd5294d3 43e60477-65bf-4407-a92d-81a6c727c0dd b6c07887-b600-4840-89c9-90d65386c9d8 ff16e816-893c-4908-890b-bc64bce22c10 179e7cef-c812-4ce0-af6e-766c8c2e15f0 683472ef-f787-4da9-b2d0-0fa34003688e b36a729c-0fea-4406-a63b-edaf26e8a662]}
  }.freeze

  EXPERIMENTS_DATA = (1..6).map do |month_number|
    month = Date::ABBR_MONTHNAMES[month_number]
    {
      start_time: DateTime.new(2024, month_number).beginning_of_month,
      end_time: DateTime.new(2024, month_number).end_of_month,
      current_patients_experiment_name: "Current Patient #{month} 2024",
      stale_patients_experiment_name: "Stale Patient #{month} 2024"
    }
  end

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    EXPERIMENTS_DATA.map do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_data[:current_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end

      ActiveRecord::Base.transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: experiment_data[:stale_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end
    end
  end

  def down
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    EXPERIMENTS_DATA.map do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_patients_experiment_name])&.cancel
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:stale_patients_experiment_name])&.cancel
    end
  end
end
