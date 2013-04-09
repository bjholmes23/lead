set_default(:mysql_host, "localhost")
set_default(:mysql_user) { application }
set_default(:mysql_rootpass) { Capistrano::CLI.password_prompt "mysql RootPass: " }
set_default(:mysql_password) { Capistrano::CLI.password_prompt "mysql Password: " }
set_default(:mysql_database) { "#{application}_production" }

namespace :mysql do
  desc "Create a database for this application."
  task :create_database, roles: :db, only: {primary: true} do
    sql = <<-SQL
      CREATE DATABASE IF NOT EXISTS #{mysql_database};
      GRANT ALL PRIVILEGES ON #{mysql_database}.* TO '#{mysql_user}'@'#{mysql_host}' IDENTIFIED BY '#{mysql_password}';
      FLUSH PRIVILEGES;
    SQL
    run %Q{#{sudo} mysql -uroot -p#{mysql_rootpass} -h #{mysql_host} -e \"#{sql}\"}
  end
  after "deploy:setup", "mysql:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "mysql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "mysql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "mysql:symlink"
end
