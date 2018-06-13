require "capistrano/setup"
require "capistrano/deploy"
require 'capistrano/rails/console'

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rbenv"
require "capistrano/rails"
require "capistrano/passenger"

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }