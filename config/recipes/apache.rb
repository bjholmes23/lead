namespace :apache do
  desc "Install certs for Apache (which itself is already installed)"
  task :install, roles: :web do
    keydir="/etc/apache2"
    run "#{sudo} openssl req -new -nodes -keyout #{keydir}/#{application_domain}.key -out #{keydir}/#{application_domain}.csr -batch"
    run "#{sudo} openssl x509 -req -days 365 -in #{keydir}/#{application_domain}.csr -signkey #{keydir}/#{application_domain}.key -out #{keydir}/#{application_domain}.crt"
    run "#{sudo} chmod 400 #{keydir}/#{application_domain}.\*"
    run "#{sudo} chown root #{keydir}/#{application_domain}.\*"
    run "#{sudo} a2enmod ssl"
    #restart
  end
  after "deploy:install", "apache:install"


  desc "Setup Apache2 configuration for this application"
  task :setup, roles: :web do
    template "apache.erb", "/tmp/apache_conf"
    run "#{sudo} mv /tmp/apache_conf /etc/apache2/sites-available/#{application}"
    run "#{sudo} rm -f /etc/apache2/sites-enabled/default"
    run "#{sudo} a2ensite #{application}"
    #restart
  end
  after "deploy:setup", "apache:setup"
  

  # Below isn't perfect in a shared environment -- would be better to restart passenger by touching app_root/tmp/restart.txt
  %w[stop start restart].each do |command|
    desc "#{command} apache2"
    task command, roles: :web do
      run "#{sudo} service apache2 #{command}"
    end
  end
end
