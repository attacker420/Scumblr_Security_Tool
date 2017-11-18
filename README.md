# Deploying Scumblr 2.0 as a Security Tool

This repo contains everything you need to deploy an instance of Scumblr https://github.com/Netflix/Scumblr to monitor for potentially malicious cyber activity. Scumblr is a Netflix open source project that allows performing periodic searches and storing / taking actions on the identified results.  I have made a few changes and added some useful Search Providers. More on that further down.  The original setup documentation can be found here: https://github.com/Netflix/Scumblr/wiki/Setting-up-Scumblr-2.0-(New-install)

# Table of Contents
- Deploying Scumblr 2.0 as a Security Tool
	- Search Providers
- SETUP
	- Requirements
	- Follow Scumblr 2.0 Docs to build
	- Follow Sketchy Docs to build
	- Configure Scumblr to use Sketchy
	- Creating Services
        - Scumblr Service
		- Sketchy Service
	- Running Scumblr
	- Running Sketchy
- Automatic Syncing
- Configuring Search Providers
- Add keys and uncomment ones in use
	- Google Custom Search Providers
	- Facebook Search Provider
	- Twitter Search Provider
	- Pastebin Custom Search Provider
	- 4chan and 8ch Custom Search Providers
	- YouTube Search Provider
- Starting it All

## Search Providers

- 4chan
- 8ch
- Onion (Tor based) Sites
- Pastebin
- Reddit


# SETUP

## Requirements

- Ubuntu Server 16.04
- install Openssh-server if not already installed
	- $ sudo apt-get install openssh-server
- Harden your Server if you have not already done so. Good instructions here:
http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
	- $ sudo apt-get update
	- $ sudo apt-get -y install git libxslt-dev libxml2-dev build-essential bison openssl zlib1g libxslt1.1 libssl-dev libxslt1-dev libxml2 libffi-dev libxslt-dev libpq-dev autoconf libc6-dev libreadline6-dev zlib1g-dev libtool libsqlite3-dev libcurl3 libmagickcore-dev ruby-build libmagickwand-dev imagemagick bundler

## Follow Scumblr 2.0 Docs to build

https://github.com/Netflix/Scumblr/wiki/Setting-up-Scumblr-2.0-(New-install)

## Follow Sketchy Docs to build

https://github.com/Netflix/Sketchy/wiki

#### Configure Scumblr to use Sketchy:

The :host option can also use an IP address and/or include the port if non-standard (i.e. "192.168.10.101:3000")
```
$ vi Scumblr/config/environments/development.rb
Rails.application.routes.default_url_options[:host] = "localhost:3000"
```

```
$ vi Scumblr/config/initializers/scumblr.rb
config.sketchy_url = "https://127.0.0.1/api/v1.0/capture"
config.sketchy_use_ssl = "sketchy_use_ssl" == "false" ? false : true # Does sketchy use ssl?
config.sketchy_verify_ssl = "false" ? false : true # Should scumblr verify sketchy's cert
#config.sketchy_tag_status_code = "sketchy_tag_status_code" # Add a tag indicating last status code sketchy received
#config.sketchy_access_token = "sketchy_access_token"
```

## Creating Sketchy and Scumblr Services
you can create a service for scumblr and sketchy.

### Scumblr service

$ vi controller/start_scumblr.sh
```
#!/bin/bash
# start scumblr
cd /home/johnsnow/Scumblr
nohup redis-server &>/dev/null & ../.rbenv/shims/bundle exec sidekiq -d -l log/sidekiq.log & nohup ../.rbenv/shims/bundle exec rails s -b 0.0.0.0 &>/dev/null &
```


$ vi controller/stop_scumblr.sh
```
#!/bin/bash
# Grabs and kill a process from the pidlist that has the word 'sidekiq 4.2.10 Scumblr'
ps aux | grep 'sidekiq 4.2.10 Scumblr' | awk '{print $2}' | xargs kill -9
# Grabs and kill a process from the pidlist that has the word 'rails master -b'
ps aux | grep 'rails master -b' | awk '{print $2}' | xargs kill -9
# Grabs and kill a process from the pidlist that has the word 'rails worker'
ps aux | grep 'rails worker' | awk '{print $2}' | xargs kill -9
# Grabs and kill a process from the pidlist that has the word 'redis-server'
ps aux | grep 'redis-server' | awk '{print $2}' | xargs kill -9
```

$ vi controller/scumblr
```
#!/bin/bash
# Scumblr Control /etc/init.d/ script
#
# Copy this file into /etc/init.d/ then chmod +x (add execution options) it and 'update-rc.d scumblr defaults'
#

case $1 in
        start)
                sudo -u johnsnow /bin/bash /home/johnsnow/Scumblr/controller/start_scumblr.sh
        ;;
        stop)
                sudo -u johnsnow /bin/bash /home/johnsnow/Scumblr/controller/stop_scumblr.sh
        ;;
        restart)
                sudo -u johnsnow /bin/bash /home/johnsnow/Scumblr/controller/stop_scumblr.sh
                sudo -u johnsnow /bin/bash /home/johnsnow/Scumblr/controller/start_scumblr.sh
        ;;
esac
exit 0
```

Set permissions and move service
```
$ chmod a+x controller/start_scumblr.sh
$ chmod a+x controller/stop_scumblr.sh
$ chmod a+x controller/scumblr
$ sudo cp controller/scumblr /etc/init.d/

update init.d service
$ update-rc.d scumblr defaults
```

### Sketchy Service
Create sketchy service

$ vi sketchy/controller/stop_sketchy.sh
```
#!/bin/bash
# stop nginx
service nginx stop
# Grabs and kill a process from the pidlist that has the word 'supervisord -c'
ps aux | grep 'supervisord -c' | awk '{print $2}' | xargs kill -9
# Grabs and kill a process from the pidlist that has the word 'celery worker'
ps aux | grep 'celery worker' | awk '{print $2}' | xargs kill -9
# Grabs and kill a process from the pidlist that has the word 'gunicorn sketchy:app'
ps aux | grep 'gunicorn sketchy:app' | awk '{print $2}' | xargs kill -9
```

$ vi sketchy/controller/start_sketchy.sh
```
#!/bin/bash
service nginx start
cd /home/johnsnow/sketchy
source sketchenv/bin/activate
supervisord -c supervisor/supervisord.ini
exit
```


$ vi sketchy/controller/sketchy
```
#!/bin/bash
# Sketchy Control /etc/init.d/ script
#
# Copy this file into /etc/init.d/ then chmod +x (add execution options) it and 'update-rc.d sketchy defaults'
#

case $1 in
        start)
                /bin/bash /home/johnsnow/sketchy/controller/start_sketchy.sh
        ;;
        stop)
                /bin/bash /home/johnsnow/sketchy/controller/stop_sketchy.sh
        ;;
        restart)
                /bin/bash /home/johnsnow/sketchy/controller/stop_sketchy.sh
                /bin/bash /home/johnsnow/sketchy/controller/start_sketchy.sh
        ;;
esac
exit 0
```

Make permission changes
```
$ chmod a+x sketchy/controller/start_sketchy.sh
$ chmod a+x sketchy/controller/stop_sketchy.sh
$ chmod a+x sketchy/controller/sketchy
$ sudo cp sketchy/controller/sketchy /etc/init.d/

update init.d service
$ update-rc.d sketchy defaults
```

## Running Scumblr
original command:
```
$ redis-server & ../.rbenv/shims/bundle exec sidekiq -l log/sidekiq.log & ../.rbenv/shims/bundle exec rails s &
```
new command:
```
$ sudo service scumblr [start|stop|restart]
```

## Running Sketchy
you can now run sketchy with a much simpler command

original command:
```
$ sudo -s
$ cd /path/to/sketchy
$ source sketchenv/bin/activate
$ cd /path/to/sketchy/supervisor
$ supervisord -c supervisor/supervisord.ini
```

new command:
```
$ sudo service sketchy [start|stop|restart]
```

# Automatic Syncing

rake sync_all will run all searches, generate emails, and use sketchy if configured

To do each function seperately:

- $ rake perform_searches # run all searches
- $ rake send_email_updates # send notifications

To set up a cron job:

- $ crontab -e
- \*/20 \* \* \* \* cd /home/johnsnow/Scumblr && /home/johnsnow/.rbenv/shims/rake run_tasks

To run rake commands as root (not required), You will need to symlink rake to /usr/bin.

	- $ which rake
	- $ which rake1.9.1
	- $ sudo ln -s /home/<USER>/.rbenv/shims/rake /usr/bin/rake


# Configuring Search Providers

Copy this repo's custom search providers into Scumblr's lib directory. The instructions below will guide you through building the necessary APIs for each search provider.

```
$ git clone https://github.com/nkleck/Scumblr_Security_Tool.git
$ cp search\ providers/* /Scumblr/lib/
```

In Scumblr/config/initializers/ you will need to edit the scumblr.rb.sample file and add the API keys. I also provided a scumblr.rb file already configured with the onion custom search provider. Just add the API keys. Instructions below!

```
$ mv scumblr.rb.sample scumblr.rb
# Add keys and uncomment ones in use
$ vi scumblr.rb
```


### Google Custom Search Providers
##### Build your project and get API keys
- Go to: https://console.developers.google.com/project
- Under "Select a project" click "Create a project.."
	- Give you project a name ie: 'scumblr-google-search'
- Click 'Enable and manage APIs'
- Click 'Custom Search API'
	- Click 'Enable'
- Click 'Credentials' on left side
	- Under 'Create Credentials' select 'API key'
	- Select 'Browser Key', and name it whatever you want
	- When your API key generates, copy it
	- Paste the API key into the "config.google_developer_key" field in /Scumblr/config/initializers/scumblr.rb

##### Build your custom search engine
- Go to: https://cse.google.com/cse/all
- Click 'New search engine' on the left
	- Type in 'www.google.com' in Sites to search
	- Name your search engine: 'scumblr-google-search'
- Under 'Edit search engine', select your search engine, click Setup
	- Click on 'Search engine ID', copy this text
	- Paste the ID into "config.google_cx" field in /Scumblr/config/initializers/scumblr.rb
	- Click on 'Public URL' and turn off
	- Enable 'Image Search'
	- Disable 'Speech Input'
- Under 'Sites to search', change the box to "Search the entire web but emphasize included sites"
	- Delete www.google.com from sites if you want, it is unnessary
	- Click Update
	- The remaining fields in /Scumblr/config/initializers/scumblr.rb are the App name and version = '1.0'

#### Search all .onion (TOR) sites custom search
- Repeat all of the steps above for a new project, API Key, and custom search, with a few changes
	- You could name the project 'scumblr-onion-search'
	- Paste the API key into 'config.google_onion_developer_key'
  	- Paste the engine ID into 'config.google_onion_cx'
  	- Under 'Sites to search', change the box to "Search only included sites"
  		- add "*.onion.link/*"
  	- Click 'Update' and your Google-Based custom searches are complete!

### Facebook Search Provider
- Go to: https://developers.facebook.com/apps
- Click 'Add a New App' button
- Copy 'App ID' and 'App Secret' into cooresponding fields in /Scumblr/config/initializers/scumblr.rb
- Facebook Search Provider is configured!


### Twitter Search Provider
- Go to: https://dev.twitter.com/apps/new
- Enter Application Name, Description, and Website (use github.com). Leave callback URL blank
- Accept the TOS
- Under the Keys and Access Tokens Tab:
	- You will generate and copy keys/secrets into the fields in /Scumblr/config/initializers/scumblr.rb
	- Copy Customer Key (API Key) into 'config.twitter_consumer_key'
	- Copy Customer Secret (API Secret) into 'config.twitter_consumer_secret'
	- Click 'Generate My Access Token and Token Secret'
		- Copy Access TOken into 'config.twitter_access_token'
		- Copy Access Token Secret into 'config.twitter_access_token_secret'
- Twitter Search Provider is configured!


### Pastebin Custom Search Provider
- The pastebin search provider requires the pastebin pro API account for scraping, acquired here:
http://pastebin.com/pro
- Then enter the public IP address of your server into this page http://pastebin.com/api_scraping_faq
- The data is scraped from the pastebin site and the query terms are compared in memory on this machine
- When using query field, entries can be a single string or multiple entries delineated by ;
- I recommend creating 1 pastebin job that runs every 10-20 minutes and pulls the last 500 paste's. This query can contain all of your searchstrings separated by a ;


### 4chan and 8ch Custom Search Providers
- These search providers utilize APIs that do not require any registration or access
- The data is scraped from the channels and the query terms are compared in memory on this machine


### YouTube Search Provider
- Go to: https://console.developers.google.com/project
- Under "Select a project" click "Create a project.."
	- Give you project a name ie: 'youtube-search'
- Click 'Enable and manage APIs'
	- Click 'YouTube Data API' and click 'Enable'
- Click 'Credentials' on left side
	- Under 'Create Credentials' select 'API key'
	- Select 'Browser Key', and name it whatever you want
	- When your API key generates, copy it
	- Paste the API key into the "config.youtube_developer_key" field in /Scumblr/config/initializers/scumblr.rb
	- The remaining fields in /Scumblr/config/initializers/scumblr.rb are the App name = 'youtube' and version = 'v3'
- YouTube Search Provider is configured

# Starting it All
if reboot, start postgres, then sketchy, then scumblr

```
$ sudo service postgresql start
$ sudo service sketchy start
$ sudo service scumblr start
```
