require 'rails_helper'

RSpec.describe ManifestsController, type: :controller do
  describe 'GET #show' do
    ['production', 'sandbox', 'demo', 'qa', 'development'].each do |env|
      it "for #{env}" do
        ENV['SIMPLE_SERVER_ENV'] = env
        get :show
        expect(response.body).to eq(File.read("public/manifest/#{env}.json"))
      end
    end
  end
end
