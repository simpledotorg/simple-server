module SimpleServerEnvHelper
  CUSTOMIZED_ENVS = %w[development qa staging sandbox production].freeze

  def style_class_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    CUSTOMIZED_ENVS.include?(env) ? "navbar-#{env}" : "navbar-light bg-light"
  end

  def logo_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}.svg" : "simple_logo.svg"

    image_tag image_name, width: 30, height: 30, class: "d-inline-block mr-2 align-top", alt: alt_for_environment

  end

  def alt_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    CUSTOMIZED_ENVS.include?(env) ? "Simple Server #{env.capitalize} Logo" : "Simple Server Logo"
  end

  def get_title_for_environment
    title = I18n.t('admin.dashboard_title')
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    return title if env.downcase == "production"

    prefix = CUSTOMIZED_ENVS.include?(env) ? "[#{env.humanize}] " : ""
    prefix + title
  end
end
