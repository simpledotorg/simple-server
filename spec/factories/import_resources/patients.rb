def build_patient_import_resource
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :rfc3339) # TODO iso8601
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :rfc3339)
  {
    resourceType: "Patient",
    meta: {
      lastUpdated: updated_at,
      createdAt: created_at
    },
    identifier: [
      {
        value: Faker::Alphanumeric.alphanumeric
      }
    ],
    gender: %w[male female other].sample,
    birthDate: Faker::Time.between(from: 20.years.ago, to: 40.years.ago),
    managingOrganization: [{value: Faker::Company.name}],
    registrationOrganization: [nil, [{value: Faker::Company.name}], []].sample,
    deceasedBoolean: Faker::Boolean.boolean,
    telecom: [nil, (1...rand(2..4)).map do
                     {value: Faker::PhoneNumber.phone_number}.then do |telecom|
                       if [true, false].sample
                         telecom[:use] = %w[work home temp old mobile].sample
                       end
                       telecom
                     end
                   end].sample,
    address: [
      {
        line: [(0...rand(2)).map { Faker::Address.street_address }, nil].sample,
        district: [Faker::Address.city, nil].sample,
        city: [Faker::Address.city, nil].sample,
        postalCode: [Faker::Address.zip_code, nil].sample
      }
    ],
    name: [nil, {text: [Faker::Name.name, nil].sample}].sample,
    active: [true, false].sample
  }
end
