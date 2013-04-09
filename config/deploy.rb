require "bundler/capistrano"

load "config/recipes/base"
load "config/recipes/apache"
load "config/recipes/mysql"
load "config/recipes/phusion"
load "config/recipes/check"

server "wuxilead.com", :web, :app, :db, primary: true

set :user, "deploy"
set :application, "wuxilead"
set :application_domain, "wuxilead.com"
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:bjholmes23/lead.git"
set :branch, "master"

# set :default_environment, {
#           'ENABLE_HTTPS' => 'yes'
# }

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "deploy_from_dev")]

after "deploy", "deploy:cleanup" # keep only the last 5 releases
