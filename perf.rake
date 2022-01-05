require "bundler"
Bundler.setup

require "derailed_benchmarks"
require "derailed_benchmarks/tasks"

class DerailedAuth < DerailedBenchmarks::AuthHelper
  def setup
    require "devise"
    require "warden"
    extend ::Warden::Test::Helpers
    extend ::Devise::TestHelpers
    Warden.test_mode!
  end

  def user
    @user = User.find_by_email("admin@simple.org")
  end

  def call(env)
    login_as(user.email_authentication)
    app.call(env)
  end
end

DerailedBenchmarks.auth = DerailedAuth.new
