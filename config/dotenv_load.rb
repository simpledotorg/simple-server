require "dotenv"
require "dotenv/rails"

class DotenvLoad
  def self.load
    Dotenv.load(".env.defaults")
    Dotenv.load(".env.#{Rails.env}.plaintxt")
    Dotenv::Railtie.load
  end

  def self.overload
    Dotenv.overload(".env.defaults")
    Dotenv.load(".env.#{Rails.env}.plaintxt")
    Dotenv::Railtie.load
  end
end