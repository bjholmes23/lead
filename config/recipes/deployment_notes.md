# Rails Deployment Notes
## Intro
These are just some notes on the process I'm taking to deploy the cocobolo site, including the DB, Web Server and App Server. We'll probably just use MySQL for the DB, but on one I might try Postgres. Later on I'll cover automated deployment with Capistrano.

For the Web Server and App Server I plan on covering four different scenarios to see what works best:

-	Web Server:
	-	[Apache](https://help.ubuntu.com/12.04/serverguide/httpd.html): older, more common, better base level skill to have
	-	[Nginx](http://nginx.org/en/download.html): newer, faster, leaner, simpler
	-	Both ended up being pretty straightforward
-	App Server:
	-	[Passenger](https://www.phusionpassenger.com/): older. Allows you to easily run multiple apps on the same version of ruby. Can also run **different versions of ruby** on the same server by using a reverse proxy to multiple standalone versions of passenger…see [here](http://blog.phusion.nl/2010/09/21/phusion-passenger-running-multiple-ruby-versions/) for more info
		-	There are a couple of ways to do this on Ubuntu -- adding a Brightbox PPA or installing a gem. The Gem **is a lot** easier
	-	[Unicorn](http://unicorn.bogomips.org/): simpler, allows for zero-downtime redeploys and perhaps better load balancing
	-	Could also look at [Thin](http://code.macournoyer.com/thin/), but don't have the time right now

The overall process will be to:

1.	Clone VM
2.	Reconfigure networking and a personal and deployment
3.	Install DB, Web Server (Apache/Nginx) and App Server (Passenger/Unicorn)
4.	Configure Rails App, DB, Web Server, App Server
5.	Optionally configure [Capistrano](https://github.com/capistrano/capistrano/wiki) automated deployment tool
5.	Initialize Rails App

## Gotchas
Here are some gotchas to get out of the way first:

-	Instead of working straight off my Dev VM, I cloned it to a new VM just in case anything goes awry. If you reinitialize the mac addresses on the clone's NIC's (to avoid duplicate MACs in a network), Ubuntu will detect them as new NIC's so you'll have to update your configuration at /etc/network/interfaces. Mine went from eth1/2 to eth4/3
-	I also wanted to update hostnames on each VM just to stay oriented if I had multiple up. To do this update /etc/hostname and /etc/hosts.
-	I started out with RVM on my clone, but removed it to use a consistent system-wide Ruby version using these [steps](http://stackoverflow.com/questions/3558656/how-to-remove-rvm-ruby-version-manager-from-my-system):

		rvm implode
		gem uninstall rvm
		# remove RVM traces from $PATH in .profile or .bashrc or .bash_profile
		rm ~/.rvm
		sudo rm /etc/rvmrc
		sudo delgroup rvm	# Delete the RVM group if you have one

-	Installing Passenger from a package manager can be a pain...just use the Gem: ``gem install passenger``
-	This guide compiles Ruby 1.9.3 from source just so that we can use a consistent version of it anytime we need to rebuild

## Common Steps
1.	I assume you have a VM already set up with working hardened SSH, personal user account, etc. Clone it.
2.	Update the hostname in /etc/hosts and /etc/hostname

		127.0.1.1		paoco
		192.168.56.50	paoco.cocobolotreefarm.com

3.	Add a deployment user

		adduser deploy				# used usual password for TCG
		adduser yourusername deploy # adds you to deploy's group
		su - deploy					# change to deploy user
		ssh-keygen -t rsa			# create ssh keys

4.	If you don't already have a JS interpriter, install Node:

		sudo apt-add-repository ppa:chris-lea/node.js
		sudo apt-get update
		sudo apt-get install nodejs

5.	Install MySQL:

		sudo apt-get install mysql-server	# record the root pw you set
		sudo netstat -tap | grep mysql		# check to see if running
		mysql -u root -p					# test login
	
	Then, create your database with the following, or use the ``createdb.sh`` script in the  appendix:
	
		mysql -uroot -p -e "CREATE DATABASE IF NOT EXISTS <your_db_name>; GRANT ALL ON <your_db_name>.* TO '<your_db_username>'@'localhost' IDENTIFIED BY '<your_db_password>'; FLUSH PRIVILEGES;"
		mysql -u <your_db_username> -p	# test login
		mysql > show databases;			# verify DB created
	
	**Note 1**: If you've forgotten your MySQL root password, you can reconfigure it with ``sudo dpkg-reconfigure mysql-server-5.5``.
	
	**Note 2**: For the purpose of scripting, you can [install MySQL without the password prompt](http://askubuntu.com/questions/79257/how-do-i-install-mysql-without-a-password-prompt) using the following:
	
		echo mysql-server mysql-server/root_password password supersecret | sudo debconf-set-selections
		echo mysql-server mysql-server/root_password_again password supersecret | sudo debconf-set-selections


5. Install system-wide Ruby from source. This also installs rubygems. First download the prequisites:

		sudo apt-get install build-essential
		sudo apt-get install bison openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev
		sudo apt-get install libcurl4-openssl-dev libopenssl-ruby libapr1-dev libaprutil1-dev
		sudo apt-get install libx11-dev libffi-dev tcl-dev tk-dev
	Then download the [latest version of Ruby](http://www.ruby-lang.org/en/downloads/), untar, and make:
	
		cd /usr/src
		sudo wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz
		sudo tar -xvf ruby-1.9.3-p392.tar.gz
		cd ruby-1.9.3-p392
		sudo ./configure --prefix=/usr/local --enable-shared --with-opt-dir=/usr/local/lib --with-openssl-dir=/usr --with-readline-dir=/usr --with-zlib-dir=/usr
		sudo make
		sudo make install
	
	**Note 1**: I'm not sure how you determine the prerequisites for ruby. I just followed [this guy's guide](http://paul-wong-jr.blogspot.hk/2012/04/installing-and-compiling-ruby-from.html) and left the Apache stuff for later.

	**Note 2**: In dev we used RVM to install Ruby, but that's meant for systems that'll handle multiple users and versions of Ruby for various projects. In a deployment scenario you're [typically] on one version of Ruby, so you install it system wide (this is debatable, as you may want to use different versions of Ruby in a shared production environment, but that's probably not a good idea).

6.	Then, put a hold (aka [lock](http://askubuntu.com/questions/18654/how-to-prevent-updating-of-a-specific-package)) on ruby packages so that running an ``apt-get upgrade`` won't overwrite what you just compiled:

		dpkg -l | grep -i ruby		# finds ruby packages
		sudo apt-mark hold ruby		# also had ruby1.8, libruby, libruby1.8
		dpkg --get-selections | grep -i ruby	# verifies hold status

	Clean out old Ruby and confirm versions:

		sudo rm /usr/bin/ruby		# Wipe old Ruby 1.8 that came with Ubuntu
		sudo ln -s /usr/local/bin/ruby /usr/bin/ruby
		sudo ln -s /usr/local/bin/gem /usr/bin/gem
		ruby -v		# ruby 1.9.3p392 (2013-02-22 revision 39386) [x86_64-linux]
		which ruby	# /usr/local/bin/ruby
		gem -v		# 1.8.23
		which gem	# /usr/local/bin/gem

7.	Install system-wide Bundler using Rubygems:

		gem install bundler			# ran as root to prevent RVM interference
		ln -s /usr/local/bin/bundle /usr/bin/bundle
		bundle -v					# Bundler version 1.3.4
		which bundle				# /usr/local/bin/bundle

You now have a VM with the right networking, users, database and system-wide Ruby installed. Now would be a good time to **take a snapshot** just incase anything goes wrong in a later step!

## Application-Specific Configuration
This will be the first time I've deployed a Rails app to a production environment. As such, there a few extra steps you have to work through when starting you app up in production vs a simple local dev environment.

1.	Make sure your database connectors are configured properly in both your **Gemfile**:

		group :test, :production do
		  gem 'mysql2'
		end	

	and your **config/database.yml**:
	
		production:
		  adapter: mysql2
		  encoding: utf8
		  reconnect: false
		  username: cocobolo
		  password: supersecret <-- This should be modified!
		  host: localhost
		  database: cocobolo_production
		  pool: 5
		  socket: /var/run/mysqld/mysqld.sock
		  timeout: 5000

2.	Need to update jquerfy-fileupload-ui.css to fix this (or find another workaround):

		/* Fix for IE 6: */
		*html .fileinput-button { <-- Causes problem
		  line-height: 22px;
		  margin: 1px -3px 0 0;
		}
		
		/* Fix for IE 7: */
		*+html .fileinput-button { <-- Causes problem
			margin: 1px 0 0 0;
		}

	The above snippet causes ``rake assets:precompile`` to fail:
	
		Invalid CSS after "*": expected "{", was "html .fileinput..."
		
		"html" may only be used at the beginning of a compound selector.

3.	**Asset Caching**: Will want to set max age to your cached assets to the highest length of time possible. This is because when you compile assets, rails appends an MD5 hash to the end of the name so that if you make any updates the name changes and the new file is re-downloaded.

	-	In Apache you have make sure the mod_expires and mod_headers modules are enabled
	
			$ sudo apachectl -m
			…
			 expires_module (shared) # look for this
			 headers_module (shared) # and this
			…
			$ sudo a2enmod expires # if expires_module not listed
			$ sudo a2enmod headers # if headers_module not listed
			$ sudo service apache2 restart
			
		Then in your site configuration you add the following directive:
		
			<LocationMatch "^/assets/.*-[0-9a-f]{32}.*$">
				Header unset ETag
				FileETag None
				# RFC says only cache for 1 year
				ExpiresActive On
				ExpiresDefault "access plus 1 year"
			</LocationMatch>

	-	Whereas in Nginx is it done like so:
		
			location ^~ /assets/ {
			  gzip_static on;
			  expires max;
			  add_header Cache-Control public;
			}

4.	**Capistrano**: Is the way to go for application deployment. Once you have a server baked and ready to go (Web/DB), then you can deploy the app from your Development or Test machine. Sounds like a plan stan.
	-	You're probably not going to want to set passwords in config files, so you can pass a variable into the task from the command line using the -s option: ``cap deploy:install mysql_password=supersecret``


## Server Setup Steps
### The Apache + Passenger Option
This is our most likely…and I think the most common…deployment scenario so I'm going to try this out first. At this state you should have the following already done:

-	VM cloned with personal + deployment users/ssh keys
-	Networking and new hostname set up on new VM
-	MySQL and system-wide Ruby (re: not via RVM) installed

The next steps will be to install Apache and Passenger, then configure them, and finally deploy our app.

1. **Install Apache** nice and easy:

		sudo apt-get install apache2 apache2-prefork-dev
		
2.	**Install Passenger** usings RubyGems and configure it for use with Apache as noted in [Sec 2.2](http://www.modrails.com/documentation/Users%20guide%20Apache.html#rubygems_generic_install) of the official guide:

		gem install passenger
		
	Then run the interactive Apache installer…
	
		passenger-install-apache2-module
	
	…and take note of the three paths it provides at the end. Drop the ``LoadModule`` line into /etc/apache2/mods-available/passenger.load:
	
		LoadModule passenger_module /usr/local/lib/ruby/gems/1.9.1/gems/
	
	And drop the ``PassengerRoot`` and ``PassengerRuby`` lines into /etc/apache2/mods-available/passenger.conf:
	
		<IfModule mod_passenger.c>
		  PassengerRoot /usr/local/lib/ruby/gems/1.9.1/gems/passenger-3.0.19
		  PassengerRuby /usr/local/bin/ruby
		</IfModule>
		
	Finally, enable Passenger by running ``sudo a2enmod passenger``. Restart Apache with ``sudo service apache2 restart`` and verify that Passenger is running with ``passenger-memory-stats``.
	
3.	**Prep a directory for the app**: We're going to put our app at /var/www. Change ownership of /var/www to deploy and allow anyone in the group to write to it:

		sudo chown -R deploy:deploy /var/www
		sudo chmod g+w /var/www
		
4.	**Configure the app**: Drop your app into /var/www (I just did a ``cp -R /home/john/rails_projects/cocobolo /var/www``), then make sure your Gemfile has the following:

		group :test, :production do
			gem 'mysql2'
		end

	And ensure your config/database.yml is set up properly (production would be nearly identical):
	
		test:
		  adapter: mysql2
		  encoding: utf8
		  reconnect: false
		  username: cocobolo
		  password: supersecret
		  host: localhost
		  database: cocobolo_test
		  pool: 5
		  socket: /var/run/mysqld/mysqld.sock
		  timeout: 5000

	Finally, if you don't have a Gemfile.lock in your app's root directory yet, run ``sudo bundle install`` to get the baseline set of gems installed. Later you'll re-do this with the unprivileged **deploy** user to create a --deployment set specific to the app.

	If you've edited the files under your regular username, then change everything back to **deploy's** ownership with ``sudo chmod -R deploy:deploy /var/www``.

5.	**Prep the environment**: su to or ssh in as **deploy** to prep the app.

		cd /var/www/cocobolo
		bundle install --deployment --without development production
		bundle exec rake db:migrate RAILS_ENV=test
		bundle exec rake db:populate RAILS_ENV=test
		bundle exec rake assets:precompile RAILS_ENV=test
		touch /var/www/cocobolo/tmp/restart.txt

6.	**Add an Apache configuration for the site**: Log back in as your sudo-able self, and drop the following into /etc/apache2/sites-available/cocobolo_test:

		<VirtualHost *:80>
		  ServerName paoco.cocobolotreefarm.com
		  ServerAlias *.paoco.cocobolotreefarm.com
		  DocumentRoot /var/www/cocobolo/public 
		  # be sure to point to public!!
		  <Directory "/var/www/cocobolo/public">
		    RackEnv test
		    Options FollowSymLinks
		    AllowOverride all
		    Options -MultiViews
		  </Directory>
		</VirtualHost>

	**Note**: I have paoco.cocobolotreefarm.com tied to my VM's local IP address in my hostfile.

7.	Finally, enable your site, disable the default site, and reload Apache:

		sudo a2ensite cocobolo_test
		sudo a2dissite default
		sudo service apache2 reload

	Now head to paoco.cocobolotreefarm (or whatever your local URL is) and see if it works!

### The Nginx + Passenger Option
This is another option. Here we'll:

-	Obtain passenger
-	Build Nginx
-	Add a configuration for our app
-	Deploy the app

Ok let's get started:

1.	**Disable the OS default Nginx**: The version of Nginx in the Ubuntu repositories doesn't support passenger out of the box. Instead it has to be compiled with the Passenger module, which'll be handled by the Passenger gem.

		# Code to put a lock on nginx... (drop this into a script)
		sudo apt-get remove nginx nginx-full nginx-light nginx-naxsi nginx-common
		sudo apt-mark hold nginx nginx-full nginx-light nginx-naxsi nginx-common
		
2.	**Install Passenger** usings RubyGems and configure it for use with Nginx as noted in [Sec 2.2](http://www.modrails.com/documentation/Users%20guide%20Apache.html#rubygems_generic_install) of the official guide:

		sudo gem install passenger

	Then run the nginx build/configuration utility...

		passenger-install-apache2-module

	...and note the installation directory (defaults to /opt/nginx). Once done it'll automagically add the proper passenger-specific configuration snippets into Nginx for you; however, we should link Nginx and its configuration from /opt/nginx to their commonly found locations:

		sudo ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx
		sudo mv /etc/nginx/ /etc/nginx.old
		sudo ln -s /opt/nginx/conf /etc/nginx
		sudo cp -R /etc/nginx.old/sites-* /etc/nginx
		sudo rm /var/run/nginx.pid
		sudo ln -s /opt/nginx/logs/nginx.pid /var/run/nginx.pid

3.	**Prep the app**: We're going to put the app at /webapps. Drop it there, and change ownership to the **deploy** user, switch to that user, then run through all the rake tasks to get set up:

		sudo mkdir /webapps
		sudo cp -R /home/youruser/rails_projects/cocobolo /webapps
		sudo chown -R deploy:deploy /webapps
		sudo chmod -R 775 /webapps
		sudo su - deploy
		cd /webapps/cocobolo
		bundle install --deployment --without development production
		# remember to update config/database.yml if necessary
		bundle exec rake db:migrate RAILS_ENV=test
		bundle exec rake db:populate RAILS_ENV=test
		bundle exec rake assets:precompile RAILS_ENV=test
		touch /webapps/cocobolo/tmp/restart.txt	

4.	**Add your site to Nginx**: Finally, add a configuration for your site to the bottom of Nginx's config (/etc/nginx/nginx.conf):

		http {
		...
			server {
				server_name pnoco.cocobolotreefarm.com;
				listen 80;
				root /webapps/cocobolo/public;
				passenger_enabled on;
				rack_env test;
			}
		}

	Now, just reload nginx ``sudo service nginx restart`` and check your site out at http://pnoco.cocobolotreefarm.com!

	**Note**: If you have an existing site and you want to put your app as a sub-URI of that site (www.example.com/myapp), see the Phusion [guide](http://www.modrails.com/documentation/Users%20guide%20Nginx.html#deploying_rack_to_sub_uri).

## References
Here are some links that helped me along the way:

-	Having trouble with your Ubuntu [Network Configuration](https://help.ubuntu.com/10.04/serverguide/network-configuration.html)? 
-	Step by step guide for **Apache + Passenger + MySQL** from [HiveLogic](http://hivelogic.com/articles/setup-guide-rails-stack-with-passenger-rvm-bundler-apache-and-mysql-on-ubun)
-	Phusion Passenger official [Apache Setup Guide](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_installing_or_upgrading_on_debian_6_or_ubuntu**)
-	Ubuntu actually has an official [guide for Ruby on Rails](https://help.ubuntu.com/12.04/serverguide/ruby-on-rails.html)
-	Github Capistrano [guide](https://help.github.com/articles/deploying-with-capistrano)
-	Another guide for [Capistrano](https://gist.github.com/jrochkind/2161449)
-	Straightforward [guide](http://www.web-l.nl/posts/21-production-rails-on-ubuntu-12-04-lts) to a production deployment, with followup on Capistrano
-	Installing Ruby from Source by [Digital Ocean](https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-ubuntu-12-04-from-source) hosting provider
-	I'm gonna modify the [Rails Ready](https://github.com/joshfng/railsready) script to suit our needs.


## Appendix
### Scripts
**user_script.sh**

Run with sudo.

		#!/bin/bash

		# add deploy user
		useradd -d /home/deploy -s /bin/bash -p $(echo supersecretpassword | openssl passwd -1 -stdin) deploy
		mkdir /home/deploy
		chown -R deploy:deploy /home/deploy
		
		# add yourself to deploy goup
		adduser myusername deploy
		
		# create ssh keys
		su deploy -c 'mkdir /home/deploy/.ssh'
		su deploy -c 'ssh-keygen -t rsa -N "" -f /home/deploy/.ssh/id_rsa'

**createdb.sh**

This is a script I found on the [web](http://jetpackweb.com/blog/2009/07/20/bash-script-to-create-mysql-database-and-user/) that will quickly set up a database from the command line for you. I altered it to lock down some of the privileges.

	#!/bin/bash
	
	EXPECTED_ARGS=3
	E_BADARGS=65
	MYSQL=`which mysql`
	
	Q1="CREATE DATABASE IF NOT EXISTS $1;"
	Q2="GRANT ALL PRIVILEGES ON $1.* TO '$2'@'localhost' IDENTIFIED BY '$3';"
	Q3="FLUSH PRIVILEGES;"
	SQL="${Q1}${Q2}${Q3}"
	
	if [ $# -ne $EXPECTED_ARGS ]; then
	        echo "Usage: $0 dbname dbuser dbpass"
	        exit $E_BADARGS
	fi
	
	$MYSQL -uroot -p -e "$SQL"

### Config Files
**/etc/apache2/mods-available/passenger.conf**

	<IfModule mod_passenger.c>
	  PassengerRoot /usr/local/lib/ruby/gems/1.9.1/gems/passenger-3.0.19
	  PassengerRuby /usr/local/bin/ruby
	</IfModule>

**/etc/apache2/mods-available/passenger.load**

	LoadModule passenger_module /usr/local/lib/ruby/gems/1.9.1/gems/passenger-3.0.19/ext/apache2/mod_passenger.so

**/etc/apache2/sites-available/cocobolo**

	<VirtualHost *:80>
	  ServerName paoco.cocobolotreefarm.com
	  ServerAlias *.paoco.cocobolotreefarm.com
	  DocumentRoot /var/www/cocobolo/public 
	  # be sure to point to public!!
	  <Directory "/var/www/cocobolo/public">
	    RackEnv test
	    Options FollowSymLinks
	    AllowOverride all
	    Options -MultiViews
	  </Directory>
	</VirtualHost>

### Tags
rails, ruby on rails, ruby, apache, nginx, ror, mongrel, mod_rails, passenger, thin, phusion passenger, capistrano