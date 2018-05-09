FactoryBot.define do
  factory :patient do
    common_names = { female: %w[anjali divya ishita priya priyanka riya shreya tanvi tanya vani],
                     male: %w[abhishek adityaamit ankit deepak mahesh rahul rohit shyam yash],
                     transgender: %w[bharathi madhu bharathi manabi anjum vani riya shreya kiran amit]}

    id { SecureRandom.uuid }
    gender { Patient.genders.keys.sample.to_sym }
    full_name { common_names[gender].sample + " " + common_names[gender].sample }
    age_when_created { rand(18..100) }
    created_at { Time.now }
    updated_at { Time.now }
  end
end
