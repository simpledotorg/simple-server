FactoryBot.define do
  factory :patient do
    common_names = { 'female'      => %w[anjali divya ishita priya priyanka riya shreya tanvi tanya vani],
                     'male'        => %w[abhishek adityaamit ankit deepak mahesh rahul rohit shyam yash],
                     'transgender' => %w[bharathi madhu bharathi manabi anjum vani riya shreya kiran amit] }

    transient do
      has_date_of_birth? { [true, false].sample }
    end

    id { SecureRandom.uuid }
    gender { Patient::GENDERS.sample }
    full_name { common_names[gender].sample + " " + common_names[gender].sample }
    status { Patient::STATUSES.sample }
    date_of_birth { Date.today if has_date_of_birth? }
    age_when_created { rand(18..100) unless has_date_of_birth? }
    created_at { Time.now }
    updated_at { Time.now }
    address
    phone_numbers { FactoryBot.create_list(:phone_number, rand(3)) }
  end
end