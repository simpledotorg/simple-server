require "capistrano/multiconfig"
require "capistrano/deploy"
require "capistrano/rails/console"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rbenv"
require "capistrano/rails"
require "capistrano/passenger"
require "capistrano/capistrano_plugin_template"
require "capistrano-db-tasks"
require "capistrano/sentry"

require "whenever/capistrano"

Dir.glob("lib/capistrano/tasks/*.rake").each(&method(:import))
