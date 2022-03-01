module SimpleServerEnvHelper
  CUSTOMIZED_ENVS = %w[development demo qa sandbox production].freeze
  ENV_ABBREVIATIONS = {development: "DEV", demo: "DEMO", test: "TEST", qa: "QA", sandbox: "SBX"}.freeze

  def style_class_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    styles = %w[navigation]
    styles += bootstrap_navbar_classes_for_environment(env)
    styles << "navbar-#{env}" if CUSTOMIZED_ENVS.include?(env)

    styles.join(" ")
  end

  def env_prefix
    env = ENV.fetch("SIMPLE_SERVER_ENV").to_sym
    ENV_ABBREVIATIONS[env] ? "[#{ENV_ABBREVIATIONS[env]}]" : nil
  end

  def logo_for_environment
    image_name = "logos/#{simple_env}/simple_logo.svg"

    image_tag image_name, width: 30, height: 30, class: "d-inline-block align-top", alt: alt_for_environment
  end

  def alt_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    CUSTOMIZED_ENVS.include?(env) ? "Simple Dashboard #{env.capitalize} Logo" : "Simple Dashboard Logo"
  end

  def mailer_logo_for_environment
    image_name = "logos/#{simple_env}/simple_logo_256.png"

    image_tag image_name, width: 48, height: 48, style: "width: 48px; height: 48px;"
  end

  def favicon_for_environment
    image_path "logos/#{simple_env}/simple_logo_favicon.png"
  end

  def apple_logo_for_environment
    image_path "logos/#{simple_env}/simple_logo_apple_touch.png"
  end

  def android_logo_for_environment(size:)
    image_path "logos/#{simple_env}/simple_logo_android_#{size}.png"
  end

  private

  def simple_env
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    CUSTOMIZED_ENVS.include?(env) ? env : "default"
  end

  def bootstrap_navbar_classes_for_environment(env)
    navbar_classes = {
      "development" => ["navbar-development"],
      "demo" => ["navbar-demo"],
      "qa" => ["navbar-qa"],
      "sandbox" => ["navbar-sandbox"],
      "production" => ["navbar-production"]
    }

    navbar_classes[env] || ["navbar-light", "bg-light"]
  end
end
