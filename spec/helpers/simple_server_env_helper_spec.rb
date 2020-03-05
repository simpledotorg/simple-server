require 'rails_helper'

RSpec.describe SimpleServerEnvHelper do
  include SimpleServerEnvHelper

  let(:simple_server_env) { 'SIMPLE_SERVER_ENV' }

  after(:each) do
    ENV[simple_server_env] = 'test'
  end

  describe 'style_class_for_environment' do
    context 'when in the default environment' do
      it 'should return the default style class' do
        ENV[simple_server_env] = 'default'

        expect(style_class_for_environment).to eq 'navbar navbar-expand-md fixed-top navbar-light bg-light'
      end
    end

    context 'when in the qa environment' do
      it 'should return the qa style class' do
        ENV[simple_server_env] = 'qa'

        expect(style_class_for_environment).to eq 'navbar navbar-expand-md fixed-top navbar-light bg-light navbar-qa'
      end
    end

    context 'when in the staging environment' do
      it 'should return the production style class' do
        ENV[simple_server_env] = 'staging'

        expect(style_class_for_environment).to eq 'navbar navbar-expand-md fixed-top navbar-light bg-light navbar-staging'
      end
    end

    context 'when in the sandbox environment' do
      it 'should return the production style class' do
        ENV[simple_server_env] = 'sandbox'

        expect(style_class_for_environment).to eq 'navbar navbar-expand-md fixed-top navbar-light navbar-sandbox'
      end
    end

    context 'when in the production environment' do
      it 'should return the production style class' do
        ENV[simple_server_env] = 'production'

        expect(style_class_for_environment).to eq 'navbar navbar-expand-md fixed-top navbar-light navbar-production'
      end
    end
  end

  describe 'logo_for_environment' do
    context 'when in the default environment' do
      it 'should return the default logo' do
        ENV[simple_server_env] = 'default'
        logo_for_default_environment = image_tag 'simple_logo.svg', width: 30, height: 30, class: 'd-inline-block mr-2 align-top', alt: 'Simple Server Logo'

        expect(logo_for_environment).to eq logo_for_default_environment
      end
    end

    context 'when in the qa environment' do
      it 'should return the QA logo' do
        ENV[simple_server_env] = 'qa'
        logo_for_qa_environment = image_tag 'simple_logo_qa.svg', width: 30, height: 30, class: 'd-inline-block mr-2 align-top', alt: 'Simple Server Qa Logo'

        expect(logo_for_environment).to eq logo_for_qa_environment
      end
    end

    context 'when in the staging environment' do
      it 'should return the staging logo' do
        ENV[simple_server_env] = 'staging'
        logo_for_staging_environment = image_tag 'simple_logo_staging.svg', width: 30, height: 30, class: 'd-inline-block mr-2 align-top', alt: 'Simple Server Staging Logo'

        expect(logo_for_environment).to eq logo_for_staging_environment
      end
    end

    context 'when in the sandbox environment' do
      it 'should return the sandbox logo' do
        ENV[simple_server_env] = 'sandbox'
        logo_for_sandbox_environment = image_tag 'simple_logo_sandbox.svg', width: 30, height: 30, class: 'd-inline-block mr-2 align-top', alt: 'Simple Server Sandbox Logo'

        expect(logo_for_environment).to eq logo_for_sandbox_environment
      end
    end

    context 'when in the production environment' do
      it 'should return the production logo' do
        ENV[simple_server_env] = 'production'
        logo_for_production_environment = image_tag 'simple_logo_production.svg', width: 30, height: 30, class: 'd-inline-block mr-2 align-top', alt: 'Simple Server Production Logo'

        expect(logo_for_environment).to eq logo_for_production_environment
      end
    end
  end

  describe 'alt_for_environment' do
    context 'when in the default environment' do
      it 'should return the default alt for the logo' do
        ENV[simple_server_env] = 'default'

        expect(alt_for_environment).to eq 'Simple Server Logo'
      end
    end

    context 'when in the qa environment' do
      it 'should return the QA alt for the logo' do
        ENV[simple_server_env] = 'qa'

        expect(alt_for_environment).to eq 'Simple Server Qa Logo'
      end
    end

    context 'when in the staging environment' do
      it 'should return the staging alt for the logo' do
        ENV[simple_server_env] = 'staging'

        expect(alt_for_environment).to eq 'Simple Server Staging Logo'
      end
    end

    context 'when in the sandbox environment' do
      it 'should return the sandbox alt for the logo' do
        ENV[simple_server_env] = 'sandbox'

        expect(alt_for_environment).to eq 'Simple Server Sandbox Logo'
      end
    end

    context 'when in the production environment' do
      it 'should return the production alt for the logo' do
        ENV[simple_server_env] = 'production'

        expect(alt_for_environment).to eq 'Simple Server Production Logo'
      end
    end
  end

  describe 'favicon_for_environment' do
    before { allow(self).to receive(:image_path).with(expected_favicon).and_return('fingerprinted_favicon') }

    context 'when in the default environment' do
      let(:expected_favicon) { 'simple_logo_favicon.png' }

      it 'should return the default logo' do
        ENV[simple_server_env] = 'default'

        expect(favicon_for_environment).to eq 'fingerprinted_favicon'
      end
    end

    SimpleServerEnvHelper::CUSTOMIZED_ENVS.each do |environment|
      context "when in the #{environment} environment" do
        let(:expected_favicon) { "simple_logo_#{environment}_favicon.png" }

        it "should return the #{environment} favicon" do
          ENV[simple_server_env] = environment

          expect(favicon_for_environment).to eq 'fingerprinted_favicon'
        end
      end
    end
  end

  describe 'mailer_logo_for_environment' do
    before { allow(self).to receive(:image_path).with(expected_logo).and_return('fingerprinted_logo') }

    context 'when in the default environment' do
      let(:expected_logo) do
        image_tag 'simple_logo-256.png', width: 48, height: 48, style: 'width: 48px; height: 48px;'
      end

      it 'should return the default logo' do
        ENV[simple_server_env] = 'default'

        expect(mailer_logo_for_environment).to eq expected_logo
      end
    end

    SimpleServerEnvHelper::CUSTOMIZED_ENVS.each do |environment|
      context "when in the #{environment} environment" do
        let(:expected_logo) do
          image_tag "simple_logo_#{environment}-256.png", width: 48, height: 48, style: 'width: 48px; height: 48px;'
        end

        it "should return the #{environment} favicon" do
          ENV[simple_server_env] = environment

          expect(mailer_logo_for_environment).to eq expected_logo
        end
      end
    end
  end
end
