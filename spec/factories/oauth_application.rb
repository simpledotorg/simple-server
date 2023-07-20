FactoryBot.define do
  factory :oauth_application, class: "Doorkeeper::Application" do
    sequence(:name) { |n| "Project #{n}" }
  end
end
