#!/bin/bash

###
# Steps:
# 1. Add users
# 2. Install Node, Apache, MySQL, Ruby pre-reqs
# 3. Install Ruby
# 4. Install gems for Bundler, Passenger
# 5. Run passenger "rake apache2" task, and drop configurations in /etc/apache2
# 6. Enable mods in apache (a2enmod)

###
# Configure the environment
shopt -s nocaseglob
set -e

ruby_version_string="1.9.3-p392"
ruby_build_dir="/usr/src"
ruby_source_tar="ruby-1.9.3-p392.tar.gz"
ruby_source_url="http://ftp.ruby-lang.org/pub/ruby/1.9/$ruby_source_tar"
ruby_source_dir="ruby-1.9.3-p392"
ruby_staged_path="/tmp/$ruby_source_tar"
script_runner=$(whoami)
setup_path="/tmp/railsinstall"
log_file="$setup_path/install_ruby_$(date +%Y.%m.%d-%H.%M.%S).log"

mkdir -p $setup_path
touch $log_file

###
# Function Definitions
print_help() {
echo "
setup_rails.sh
==============

	Prep the Rails environment on an Ubuntu server to run the Cocobolo Tree Farm web site. Script will:
		-Create a deploy user
		-Install Apache, MySQL, Node.js
		-Locate or download then install Ruby 1.9.3
		-Install gems for Bundler and Passenger
		-Configure Apache
	Must be either run with sudo or as root! This is intended to be installed on a fresh, bare Ubuntu 12.04 server. It may work on other versions of Ubuntu or Debian.

	Usage:
		./setup_rails.sh [Required: -d \"deploy_user_password\" -m \"mysql_root_password\"] [Optional: -k /path/to/deploy/pubkey -u \"custom_user_name\" -p \"custom_user_password\" -j /path/to/custom_user/pubkey -h (print this help)]

	Options:

	-d	-	Deploy user password (required)

	-k	-	Path to deploy user's public SSH key (optional)

	-m	-	MySQL root user password (required)

	-u	-	Custom user account name (optional)

	-p	-	Custom user account password (optional)

	-j	-	Path to custom user account public SSH key (optional)

	-h	-	Show this help menu

	Examples:
		./setup_rails.sh -d othersecret -m supersecret
		./setup_rails.sh -d othersecret -m supersecret -u john -p anothersecret
"
	
	exit 1
}

control_c()
{
	echo "Exiting install prematurely (Ctrl-C pressed)..." >> $log_file
  echo -en "\n\n*** Exiting ***\n\n"
  exit 1
}

create_users() {
	echo -en "\n\n==> Creating deploy user...\n\n" | tee -a $log_file
	useradd -d /home/deploy -m -s /bin/bash -p $(echo $deploy_userpass | openssl passwd -1 -stdin) -G sudo deploy 2>&1 | tee -a $log_file
	su deploy -c 'mkdir /home/deploy/.ssh' 2>&1 | tee -a $log_file
	if [[ -n $deploy_userpubkey ]]; then
		su deploy -c 'mv $deploy_userpubkey /home/deploy/.ssh/authorized_keys'
	else
		su deploy -c 'ssh-keygen -t rsa -N "" -f /home/deploy/.ssh/id_rsa' 2>&1 | tee -a $log_file # create ssh keys
		su deploy -c 'mv /home/deploy/.ssh/id_rsa.pub /home/deploy/.ssh/authorized_keys'
		echo "Deploy ssh key generated at ~/.ssh/id_rsa" | tee -a $log_file
	fi
	echo -en "==> done...\n***\n" | tee -a $log_file

	if [[ -n $custom_username ]] && [[ -n $custom_userpass ]]; then
		echo -en "\n\n==>Creating custom user $custom_username..." | tee -a $log_file
		useradd -d /home/$custom_username -m -s /bin/bash -p $(echo $custom_userpass | openssl passwd -1 -stdin) $custom_username 2>&1 | tee -a $log_file
		mkdir /home/$custom_username/.ssh && chown $custom_username:$custom_username /home/$custom_username/.ssh 2>&1 | tee -a $log_file
		if [[ -n $custom_userpubkey ]]; then
			mv $custom_userpubkey /home/$custom_username/.ssh/authorized_keys
		else
			su $custom_username -c 'ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa' 2>&1 | tee -a $log_file # create ssh keys
			mv /home/$custom_username/.ssh/id_rsa.pub /home/$custom_username/.ssh/authorized_keys
			echo "$custom_username ssh key generated at ~/.ssh/id_rsa" | tee -a $log_file
		fi
		echo -en "==> done...\n***\n"
	fi
}

install_node() {
	echo -en "\n\n==> Installing Node.js...\n" | tee -a $log_file
	
	if [[ -n $(which node) ]]; then
		echo "Node ($(node -v)) already installed...manually upgrade if desired." | tee -a $log_file
	else
		apt-add-repository ppa:chris-lea/node.js 2>&1 | tee -a $log_file
		apt-get update 2>&1 | tee -a $log_file
		apt-get -y install nodejs 2>&1 | tee -a $log_file
	fi

	echo -en "==> done...\n***\n" | tee -a $log_file
}

install_apache() {
	echo -en "\n\n==> Installing Apache...\n" | tee -a $log_file

	if [[ -n $(which apache2) ]]; then
		echo "Apache ($(apache2 -v)) already installed...manually upgrade if desired." | tee -a $log_file
	else
		apt-get -y install apache2 apache2-prefork-dev
	fi
	echo -en "\n==> done...\n***\n" | tee -a $log_file
}

install_db() {
	echo -en "\n\n==> Installing MySQL...\n" | tee -a $log_file
	
	echo mysql-server mysql-server/root_password password $mysql_rootpass | debconf-set-selections 2>&1 | tee -a $log_file
	echo mysql-server mysql-server/root_password_again password $mysql_rootpass | debconf-set-selections 2>&1 | tee -a $log_file
	
	apt-get -y install \
		libsqlite3-0 sqlite3 libsqlite3-dev \
		mysql-server mysql-client libmysqlclient-dev 2>> $log_file

	if [[ $(sudo netstat -tap | grep mysql | awk '{print $6}') == "LISTEN" ]]; then
		echo "MySQL is now running!"
	else
		echo "MySQL is not running...attempting to restart"
		service mysql restart 2>&1 | tee -a $log_file
	fi
	
	echo -en "\n==> done...\n***\n" | tee -a $log_file
}

install_ruby_prereqs() {
	echo -en "\n\n==> Install Ruby Build Pre-reqs...\n" | tee -a $log_file

	# Freeze Ruby Packages in Apt
	echo "Freeze Ruby Packages in Apt" 2>&1 | tee -a $LOGFILE

	for i in $(dpkg -l | grep -i ruby | awk '{print $2}'); do
		apt-mark hold $i 2>&1 | tee -a $log_file
	done

	# Wipe old Ruby 1.8 that came with Ubuntu
	if [[ -n $(which ruby) ]]; then
		rm $(which ruby)
	fi

	if [[ -n $(which gem) ]]; then
		rm $(which gem)
	fi

	# Install Build Pre-requisites
	apt-get -y install build-essential bison openssl \
		libreadline6 libreadline6-dev zlib1g zlib1g-dev \
		libssl-dev libyaml-dev libxml2-dev libxslt-dev \
		autoconf libc6-dev ncurses-dev libcurl4-openssl-dev \
		libopenssl-ruby libapr1-dev libaprutil1-dev libx11-dev \
		libffi-dev tcl-dev tk-dev linux-headers-server \
		imagemagick libmagickwand-dev git 2>&1 | tee -a $log_file

	echo -en "\n==> done...\n***\n" | tee -a $log_file
}

build_ruby() {
	echo -en "\n\n==> Building Ruby. This'll take a while...\n" | tee -a $log_file

	# Stage the source: Download Ruby if not already present
	if [[ ! -e $ruby_build_dir/$ruby_source_tar ]]; then
		cd $ruby_build_dir && wget $ruby_source_url 2>&1 | tee -a $log_file
	fi

	#mv $ruby_source_tar $ruby_build_dir
	cd $ruby_build_dir && tar -xvf $ruby_source_tar 2>&1 | tee -a $log_file

	cd $ruby_build_dir/$ruby_source_dir \
	 && ./configure --prefix=/usr/local --enable-shared --with-opt-dir=/usr/local/lib 2>&1 | tee -a $log_file \
	  && make 2>&1 | tee -a $log_file \
	   && make test 2>&1 | tee -a $log_file \
	    && make install 2>&1 | tee -a $log_file

	# Link Ruby and Rubygems (gem)
	#echo "Linking Ruby and Rubygems" 2>&1 | tee -a $LOGFILE
	#ln -s /usr/local/bin/ruby /usr/bin/ruby
	#ln -s /usr/local/bin/gem /usr/bin/gem

	echo -en "\n==> done...\n***\n" | tee -a $log_file
}

install_gems() {
	echo -en "\n\n==> Install gems for bundler and passenger...\n" | tee -a $log_file

	echo "Installing Bundler and Passenger" 2>&1 | tee -a $log_file
	gem install bundler 2>&1 | tee -a $log_file
	#ln -s /usr/local/bin/bundle /usr/bin/bundle
	gem install passenger -v "=3.0.19"

	echo -en "\n==> done...\n***\n" | tee -a $log_file
}

configure_apache() {
	echo -en "\n\n==> Configure apache: Run passenger rake task...\n" | tee -a $log_file

	cd $(passenger-config --root) && rake apache2

	echo -en "\n==> done...\n***\n" | tee -a $log_file

	echo -en "\n\n==> Configure apache: Create passenger configuration files...\n" | tee -a $log_file

	echo -en "<IfModule mod_passenger.c>\n\tPassengerRoot $(passenger-config --root)\n\tPassengerRuby $(which ruby)\n</IfModule>" > /etc/apache2/mods-available/passenger.conf
	echo -en "LoadModule passenger_module $(passenger-config --root)/ext/apache2/mod_passenger.so" > /etc/apache2/mods-available/passenger.load
	a2enmod passenger
	a2enmod expires
	a2enmod headers

	chown -R deploy:deploy /var/www
	chmod g+w /var/www
	service apache2 restart

	echo -en "\n==> done...\n***\n" | tee -a $log_file
}


###
# Set up the script flow below

# trap keyboard interrupt (control-c)
trap control_c SIGINT

###
# Grab options from command line
# d = deploy user pw (required)
# m = mysql password (required)
# u = username (optional)
# p = password (optional)
# h = help (optional)
while getopts ":d:k:m:u:p:j:h" option; do
	case $option
		in
			d)
				deploy_userpass=$OPTARG
				;;
			k)
				deploy_userpubkey=$OPTARG
				;;
			m)
				mysql_rootpass=$OPTARG
				;;
			u) 
				custom_username=$OPTARG
				;;
			p)
				custom_userpass=$OPTARG
				;;
			j)
				custom_userpubkey=$OPTARG
				;;
			h)
				print_help
				;;
			\?)
				echo "Unrecognized option: ${OPTARG}";
				print_help
				;;
			:)
				echo "Option -$OPTARG requires an argument." >&2
				print_help
				;;
	esac
done

# Verify Presence of Required Options
if [[ -z $deploy_userpass ]] || [[ -z $mysql_rootpass ]]; then
	print_help
fi

# Create Deploy and optional users
create_users

# Install Node
install_node

# Install Apache
install_apache

# Install SQLite and MySQL
install_db

# Instal Ruby Build Pre-reqs
install_ruby_prereqs

# Build Ruby
build_ruby

# Install Bundler and Passenger gems
install_gems

# Configure Apache
configure_apache

