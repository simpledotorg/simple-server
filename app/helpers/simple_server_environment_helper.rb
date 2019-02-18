module SimpleServerEnvironmentHelper
  SIMPLE_SERVER_ENV = "SIMPLE_SERVER_ENV".freeze

  def style_class_for_environment
    if ENV.include? SIMPLE_SERVER_ENV then
      case ENV[SIMPLE_SERVER_ENV]
      when 'production'
        'navbar-production'
      when 'staging'
        'navbar-staging'
      when 'sandbox'
        'navbar-sandbox'
      end
    end
  end

  def self.img_for_environment
    if ENV.include? SIMPLE_SERVER_ENV
      case ENV[SIMPLE_SERVER_ENV]
      when 'production'
        'simple_logo.svg'
      when 'staging'
        'simple_logo_staging.svg'
      when 'sandbox'
        'simple_logo_sandbox.svg'
      end
    else
      'simple_logo.svg'
    end
  end

  def self.alt_for_environment
    if ENV.include? SIMPLE_SERVER_ENV
      case ENV[SIMPLE_SERVER_ENV]
      when 'production'
        'Simple Server Logo'
      when 'staging'
        'Simple Server Staging Logo'
      when 'sandbox'
        'Simple Server Sandbox Logo'
      end
    else
      'Simple Server Logo'
    end
  end
end

