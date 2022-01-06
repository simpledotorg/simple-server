# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimpleServerEnvHelper do
  include SimpleServerEnvHelper

  let(:simple_server_env) { "SIMPLE_SERVER_ENV" }

  after(:each) do
    ENV[simple_server_env] = "test"
  end

  describe "style_class_for_environment" do
    context "when in the default environment" do
      it "should return the default style class" do
        ENV[simple_server_env] = "default"

        expect(style_class_for_environment).to eq "navbar navbar-expand-md fixed-top navbar-light bg-light"
      end
    end

    context "when in the qa environment" do
      it "should return the qa style class" do
        ENV[simple_server_env] = "qa"

        expect(style_class_for_environment).to eq "navbar navbar-expand-md fixed-top navbar-light bg-light navbar-qa"
      end
    end

    context "when in the demo environment" do
      it "should return the production style class" do
        ENV[simple_server_env] = "demo"

        expect(style_class_for_environment).to eq "navbar navbar-expand-md fixed-top navbar-light bg-light navbar-demo"
      end
    end

    context "when in the sandbox environment" do
      it "should return the production style class" do
        ENV[simple_server_env] = "sandbox"

        expect(style_class_for_environment).to eq "navbar navbar-expand-md fixed-top navbar-light navbar-sandbox"
      end
    end

    context "when in the production environment" do
      it "should return the production style class" do
        ENV[simple_server_env] = "production"

        expect(style_class_for_environment).to eq "navbar navbar-expand-md fixed-top navbar-light navbar-production"
      end
    end
  end

  describe "env_prefix" do
    it "returns abbreviated name for our environments" do
      expect(env_prefix).to eq("[TEST]")
      ENV[simple_server_env] = "sandbox"
      expect(env_prefix).to eq("[SBX]")
    end

    it "defaults to nil" do
      ENV[simple_server_env] = "default"
      expect(env_prefix).to be_nil
    end

    it "returns nil for production" do
      ENV[simple_server_env] = "production"
      expect(env_prefix).to be_nil
    end
  end

  describe "logo_for_environment" do
    context "when in the default environment" do
      it "should return the default logo" do
        ENV[simple_server_env] = "default"
        logo_for_default_environment = image_tag "logos/default/simple_logo.svg", width: 30, height: 30, class: "d-inline-block align-top", alt: "Simple Dashboard Logo"

        expect(logo_for_environment).to eq logo_for_default_environment
      end
    end

    context "when in the qa environment" do
      it "should return the QA logo" do
        ENV[simple_server_env] = "qa"
        logo_for_qa_environment = image_tag "logos/qa/simple_logo.svg", width: 30, height: 30, class: "d-inline-block align-top", alt: "Simple Dashboard Qa Logo"

        expect(logo_for_environment).to eq logo_for_qa_environment
      end
    end

    context "when in the demo environment" do
      it "should return the demo logo" do
        ENV[simple_server_env] = "demo"
        logo_for_demo_environment = image_tag "logos/demo/simple_logo.svg", width: 30, height: 30, class: "d-inline-block align-top", alt: "Simple Dashboard Demo Logo"

        expect(logo_for_environment).to eq logo_for_demo_environment
      end
    end

    context "when in the sandbox environment" do
      it "should return the sandbox logo" do
        ENV[simple_server_env] = "sandbox"
        logo_for_sandbox_environment = image_tag "logos/sandbox/simple_logo.svg", width: 30, height: 30, class: "d-inline-block align-top", alt: "Simple Dashboard Sandbox Logo"

        expect(logo_for_environment).to eq logo_for_sandbox_environment
      end
    end

    context "when in the production environment" do
      it "should return the production logo" do
        ENV[simple_server_env] = "production"
        logo_for_production_environment = image_tag "logos/production/simple_logo.svg", width: 30, height: 30, class: "d-inline-block align-top", alt: "Simple Dashboard Production Logo"

        expect(logo_for_environment).to eq logo_for_production_environment
      end
    end
  end

  describe "alt_for_environment" do
    context "when in the default environment" do
      it "should return the default alt for the logo" do
        ENV[simple_server_env] = "default"

        expect(alt_for_environment).to eq "Simple Dashboard Logo"
      end
    end

    context "when in the qa environment" do
      it "should return the QA alt for the logo" do
        ENV[simple_server_env] = "qa"

        expect(alt_for_environment).to eq "Simple Dashboard Qa Logo"
      end
    end

    context "when in the demo environment" do
      it "should return the demo alt for the logo" do
        ENV[simple_server_env] = "demo"

        expect(alt_for_environment).to eq "Simple Dashboard Demo Logo"
      end
    end

    context "when in the sandbox environment" do
      it "should return the sandbox alt for the logo" do
        ENV[simple_server_env] = "sandbox"

        expect(alt_for_environment).to eq "Simple Dashboard Sandbox Logo"
      end
    end

    context "when in the production environment" do
      it "should return the production alt for the logo" do
        ENV[simple_server_env] = "production"

        expect(alt_for_environment).to eq "Simple Dashboard Production Logo"
      end
    end
  end

  describe "apple_logo_for_environment" do
    before { allow(self).to receive(:image_path).with(expected_apple_touch).and_return("fingerprinted_apple_touch") }

    context "when in the default environment" do
      let(:expected_apple_touch) { "logos/default/simple_logo_apple_touch.png" }

      it "should return the default logo" do
        ENV[simple_server_env] = "default"

        expect(apple_logo_for_environment).to eq "fingerprinted_apple_touch"
      end
    end

    SimpleServerEnvHelper::CUSTOMIZED_ENVS.each do |environment|
      context "when in the #{environment} environment" do
        let(:expected_apple_touch) { "logos/#{environment}/simple_logo_apple_touch.png" }

        it "should return the #{environment} apple_touch" do
          ENV[simple_server_env] = environment

          expect(apple_logo_for_environment).to eq "fingerprinted_apple_touch"
        end
      end
    end
  end

  describe "android_logo_for_environment" do
    before { allow(self).to receive(:image_path).with(expected_logo_android_192).and_return("fingerprinted_logo_android_192") }

    context "when in the default environment" do
      let(:expected_logo_android_192) { "logos/default/simple_logo_android_192.png" }

      it "should return the default logo" do
        ENV[simple_server_env] = "default"

        expect(android_logo_for_environment(size: "192")).to eq "fingerprinted_logo_android_192"
      end
    end

    SimpleServerEnvHelper::CUSTOMIZED_ENVS.each do |environment|
      context "when in the #{environment} environment" do
        let(:expected_logo_android_192) { "logos/#{environment}/simple_logo_android_192.png" }

        it "should return the #{environment} logo_android_192" do
          ENV[simple_server_env] = environment

          expect(android_logo_for_environment(size: "192")).to eq "fingerprinted_logo_android_192"
        end
      end
    end
  end

  describe "favicon_for_environment" do
    before { allow(self).to receive(:image_path).with(expected_favicon).and_return("fingerprinted_favicon") }

    context "when in the default environment" do
      let(:expected_favicon) { "logos/default/simple_logo_favicon.png" }

      it "should return the default logo" do
        ENV[simple_server_env] = "default"

        expect(favicon_for_environment).to eq "fingerprinted_favicon"
      end
    end

    SimpleServerEnvHelper::CUSTOMIZED_ENVS.each do |environment|
      context "when in the #{environment} environment" do
        let(:expected_favicon) { "logos/#{environment}/simple_logo_favicon.png" }

        it "should return the #{environment} favicon" do
          ENV[simple_server_env] = environment

          expect(favicon_for_environment).to eq "fingerprinted_favicon"
        end
      end
    end
  end

  describe "mailer_logo_for_environment" do
    before { allow(self).to receive(:image_path).with(expected_logo).and_return("fingerprinted_logo") }

    context "when in the default environment" do
      let(:expected_logo) do
        image_tag "logos/default/simple_logo_256.png", width: 48, height: 48, style: "width: 48px; height: 48px;"
      end

      it "should return the default logo" do
        ENV[simple_server_env] = "default"

        expect(mailer_logo_for_environment).to eq expected_logo
      end
    end

    SimpleServerEnvHelper::CUSTOMIZED_ENVS.each do |environment|
      context "when in the #{environment} environment" do
        let(:expected_logo) do
          image_tag "logos/#{environment}/simple_logo_256.png", width: 48, height: 48, style: "width: 48px; height: 48px;"
        end

        it "should return the #{environment} favicon" do
          ENV[simple_server_env] = environment

          expect(mailer_logo_for_environment).to eq expected_logo
        end
      end
    end
  end
end
