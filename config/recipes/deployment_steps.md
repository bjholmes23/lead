# How to deploy the app on a fresh server

1.	Grab a fresh Ubuntu 12.04 machine
2.	Set up your own user acount
3.	Drop setup_rails.sh and a deploy public key (id_rsa.pub) onto the server
4.	To install Ruby, MySQL, Apache and Phusion, as root run ``./setup_rails.sh -p <deploy password> -k </path/to/deploy/id_rsa.pub> -m <mysql root password>``
5.	In order to access git, generate another keypair for the deploy user and add the public key to your git repo.
6.	On your dev machine, run:

		cap deploy:install
		cap deploy:setup
		cap deploy:cold
		
7.	Finally, if your database is empty you'll have to generate some data. On the staging server, from /var/www/cocobolo/current run ``rake db:populate RAILS_ENV=production``.
8.	Test out the app. If it's not working:
	-	Make sure your keys are in shape. Capistrano is supposed to pass your key along to the staging server for git checkouts (although I've found this to be finnicky); if that's not working make sure your Staging box has a key that can pull from Git.
	-	Make sure the Apache configuration is correct, that the default site is disabled, and that you have the passenger, headers, expires, and ssl mods enabled (a2enmod <modname>). These are handled in the script but play it safe.
	-	Finally, the app is set up as a virtual host under the name cocobolotreefarm.com, meaning apache inspects the URL request to determine what site to serve. To make the URL match the virtual host, I just edited my local host file to make cocobolotreefarm.com match the Staging box's IP.