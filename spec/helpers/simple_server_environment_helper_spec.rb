require 'rails_helper'

RSpec.describe SimpleServerEnvironmentHelper do
  include SimpleServerEnvironmentHelper

  let(:simple_server_env) {"SIMPLE_SERVER_ENV"}

  after(:each) do
    ENV[simple_server_env] = "test"
  end

  describe 'style_class_for_environment' do
    it 'should return the correct style class for the environment' do
      ENV[simple_server_env] = "qa"

      style = style_class_for_environment
      puts style
      expect(style_class_for_environment).to eq '.navbar-qa'

      ENV[simple_server_env] = "production"

      expect(style_class_for_environment).to eq '.navbar-production'

      ENV[simple_server_env] = "sandbox"

      expect(style_class_for_environment).to eq '.navbar-sandbox'
    end
  end

  describe 'logo_for_environment' do
    it 'should return the correct logo for the environment' do
      ENV[simple_server_env] = "qa"
      logo_for_qa = image_tag 'simple_logo_qa.svg', width: 30, height: 30, class: "d-inline-block mr-2 align-top", alt: 'Simple Server Qa Logo'

      expect(logo_for_environment).to eq logo_for_qa

      ENV[simple_server_env] = "production"
      logo_for_production = image_tag 'simple_logo_production.svg', width: 30, height: 30, class: "d-inline-block mr-2 align-top", alt: 'Simple Server Production Logo'

      expect(logo_for_environment).to eq logo_for_production

      ENV[simple_server_env] = "sandbox"
      logo_for_sandbox = image_tag 'simple_logo_sandbox.svg', width: 30, height: 30, class: "d-inline-block mr-2 align-top", alt: 'Simple Server Sandbox Logo'

      expect(logo_for_environment).to eq logo_for_sandbox

      ENV[simple_server_env] = "staging"
      logo_for_staging = image_tag 'simple_logo_staging.svg', width: 30, height: 30, class: "d-inline-block mr-2 align-top", alt: 'Simple Server Staging Logo'

      expect(logo_for_environment).to eq logo_for_staging
    end
  end

  describe 'alt_for_environment' do
    it 'should return the correct image alt for the environment' do
      ENV[simple_server_env] = "qa"

      expect(alt_for_environment).to eq 'Simple Server Qa Logo'

      ENV[simple_server_env] = "production"

      expect(alt_for_environment).to eq 'Simple Server Production Logo'

      ENV[simple_server_env] = "sandbox"

      expect(alt_for_environment).to eq 'Simple Server Sandbox Logo'

      ENV[simple_server_env] = "development"

      expect(alt_for_environment).to eq 'Simple Server Logo'

      ENV[simple_server_env] = "staging"

      expect(alt_for_environment).to eq 'Simple Server Staging Logo'
    end
  end
end

