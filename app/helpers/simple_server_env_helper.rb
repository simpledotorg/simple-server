module SimpleServerEnvHelper
  CUSTOMIZED_ENVS = %w[development qa staging sandbox production].freeze

  def style_class_for_environment
    env = ENV.fetch('SIMPLE_SERVER_ENV')

    styles = %w[navbar navbar-expand-md fixed-top]
    styles += bootstrap_navbar_classes_for_environment(env)
    styles << "navbar-#{env}" if CUSTOMIZED_ENVS.include?(env)

    styles.join(' ')
  end

  def logo_for_environment
    env = ENV.fetch('SIMPLE_SERVER_ENV')

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}.svg" : 'simple_logo.svg'

    image_tag image_name, width: 30, height: 30, class: 'd-inline-block mr-2 align-top', alt: alt_for_environment
  end

  def alt_for_environment
    env = ENV.fetch('SIMPLE_SERVER_ENV')

    CUSTOMIZED_ENVS.include?(env) ? "Simple Dashboard #{env.capitalize} Logo" : 'Simple Dashboard Logo'
  end

  def favicon_for_environment
    env = ENV.fetch('SIMPLE_SERVER_ENV')

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}_favicon.png" : 'simple_logo_favicon.png'

    image_path(image_name)
  end

  def apple_touch_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}_apple_touch.png" : "simple_logo_apple_touch.png"

    image_path(image_name)
  end

  def logo_android_192_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}_android_192.png" : "simple_logo_android_192.png"

    image_path(image_name)
  end

  def logo_android_512_for_environment
    env = ENV.fetch("SIMPLE_SERVER_ENV")

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}_android_512.png" : "simple_logo_android_512.png"

    image_path(image_name)
  end

  def mailer_logo_for_environment
    env = ENV.fetch('SIMPLE_SERVER_ENV')

    image_name = CUSTOMIZED_ENVS.include?(env) ? "simple_logo_#{env}-256.png" : 'simple_logo-256.png'

    image_tag image_name, width: 48, height: 48, style: 'width: 48px; height: 48px;'
  end

  def get_title_for_environment
    title = I18n.t('admin.dashboard_title')
    env = ENV.fetch('SIMPLE_SERVER_ENV')

    return title if env.downcase == 'production'

    prefix = CUSTOMIZED_ENVS.include?(env) ? "[#{env.humanize}] " : ''
    prefix + title
  end

  private

  def bootstrap_navbar_classes_for_environment(env)
    navbar_classes = {
      'development' => ['navbar-light', 'bg-light'],
      'staging' => ['navbar-light', 'bg-light'],
      'qa' => ['navbar-light', 'bg-light'],
      'sandbox' => ['navbar-light'],
      'production' => ['navbar-light'],
    }

    navbar_classes[env] || ['navbar-light', 'bg-light']
  end
end
