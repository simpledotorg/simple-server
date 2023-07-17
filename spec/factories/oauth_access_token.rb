FactoryBot.define do
  factory :oauth_access_token, class: "Doorkeeper::AccessToken" do
    application { oauth_application }
  end
end
