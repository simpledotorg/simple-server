require "dotenv"
require "dotenv/rails"

class DotenvLoad
  def self.root
    Rails.root
  end

  def self.load
    Dotenv.load(".env.#{Rails.env}.plaintxt", "env.defaults")
    Dotenv::Railtie.load
  end

  def self.standard_dotenv_files
    [
      root.join(".env.#{Rails.env}.local"),
      (root.join(".env.local") unless Rails.env.test?),
      root.join(".env.#{Rails.env}"),
      root.join(".env")
    ].compact
  end

  def self.overload
    Dotenv.overload(".env.defaults")
    Dotenv.load(".env.#{Rails.env}.plaintxt")
    Dotenv::Railtie.load
  end
end