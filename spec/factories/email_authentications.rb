FactoryBot.define do
  factory :email_authentication do
    transient do
      master_user { create :master_user }
    end
    email { Faker::Internet.email }
    password { Faker::Internet.password }

    after :create do |email_authentication, options|
      options.master_user.email_authentications = [email_authentication]
      options.master_user.save
    end

    factory :admin
  end
end
