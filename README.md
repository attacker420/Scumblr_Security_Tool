# Deploying Scumblr as a Security Tool

This repo contains everything you need to deploy an instance of Scumblr https://github.com/Netflix/Scumblr to monitor for potentially malicious cyber activity. Scumblr is a Netflix open source project that allows performing periodic searches and storing / taking actions on the identified results.  I have made a few changes and added some useful Search Providers. More on that further down.  The origional setup documentation can be found here: https://github.com/Netflix/Scumblr/wiki

# Table of Contents

<!-- MarkdownTOC depth=3 -->

- Search Providers
- SETUP
    - Requirements
    - Pre-Installation Items
    - Install Ruby on Rails
    - Install Application Dependencies
    - Setup Applicaiton
    - Running Scumblr
- Automatic Syncing
- Configuring Search Providers
    - Google Custom Search Providers
    - Facebook Search Provider
    - Twitter Search Provider
    - Pastebin Custom Search Provider
    - 4chan and 8ch Custom Search Providers
    - YouTube Search Provider
- Sketchy Integration
- Slack Integration
- MISC

<!-- /MarkdownTOC -->

## Search Providers

- 4chan
- 8ch
- APTNotes
- Facebook
- Github
- Google
- Onion (Tor based) Sites
- Pastebin
- Reddit
- rss
- Twitter
- YouTube

# SETUP

## Requirements

- Ubuntu Server 14.04
- install Openssh-server if not already installed
	- $ sudo apt-get install openssh-server 
- Harden your Server if you have not already done so. Good instructions here:
http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers
	- $ sudo apt-get update
	- $ sudo apt-get -y install git libxslt-dev libxml2-dev build-essential bison openssl zlib1g libxslt1.1 libssl-dev libxslt1-dev libxml2 libffi-dev libxslt-dev libpq-dev autoconf libc6-dev libreadline6-dev zlib1g-dev libtool libsqlite3-dev libcurl3 libmagickcore-dev ruby-build libmagickwand-dev imagemagick bundler


## Pre-Installation Items
Install Rbenv/Ruby

- $ cd ~
- $ git clone https://github.com/sstephenson/rbenv.git .rbenv
- $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
- $ echo 'eval "$(rbenv init -)"' >> ~/.bashrc
- $ exec $SHELL

- $ git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
- $ echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
- $ exec $SHELL

- $ rbenv install 2.0.0-p481
- $ rbenv global 2.0.0-p481
- $ ruby -v

## Install Ruby on Rails
- $ gem install bundler --no-ri --no-rdoc
- $ rbenv rehash
- $ gem install rails -v 4.0.9 

## Install Application Dependencies
- $ sudo apt-get install redis-server
- $ gem install sidekiq
- $ rbenv rehash

## Setup Applicaiton
- $ git clone https://github.com/Netflix/Scumblr.git
- $ cd Scumblr
- $ bundle install
- $ rake db:create
- $ rake db:schema:load

#### Create an Admin User
Create Admin user:
- $ ../.rbenv/versions/2.0.0-p481/bin/rails c

In the console:

- user = User.new

- user.email = "<Valid email address>"

- user.password = "<Password>"

- user.password_confirmation = "<Password>"

- user.admin = true

- user.save


## Running Scumblr
- $ redis-server & ../.rbenv/shims/bundle exec sidekiq -l log/sidekiq.log & ../.rbenv/shims/bundle exec rails s &

http://localhost:3000

#### Configure Email or Sketchy:

The :host option can also use an IP address and/or include the port if non-standard (i.e. "192.168.10.101:3000")

- $ vi Scumblr/config/environments/production.rb | test.rb

Rails.application.routes.default_url_options[:host] = "scumblr.com"
Rails.application.routes.default_url_options[:protocol] = "https"


# Automatic Syncing

rake sync_all will run all searches, generate emails, and use sketchy if configured

From the command line at the Scumblr root path, run:

- $ rake sync_all


To do each function seperately:

- $ rake perform_searches # run all searches
- $ rake send_email_updates # send notifications

To set up a cron job:

- $ crontab -e
- 0 \* \* \* \* rake -f /home/<USER>/Scumblr/Rakefile sync_all (no quotes)

To run rake commands as root (not required):

- You will need to symlink rake to /usr/bin

- $ which rake
- $ which rake1.9.1
- $ sudo ln -s /home/<USER>/.rbenv/shims/rake /usr/bin/rake


# Configuring Search Providers
Copy this repo's custom search providers into Scumblr's lib directory. The instructions below will guide you through building the necessary APIs for each search provider. 

- $ git clone https://github.com/nkleck/Scumblr_Security_Tool.git

- $ mv search\ providers/ /Scumblr/lib/ 


In Scumblr/config you will need to edit the scumblr.rb.sample file and add the API keys. I also provided a scumblr.rb file already configured with the onion custom search provider. Just add the API keys. Instructions below!

- $ mv scumblr.rb.sample scumblr.rb

Add keys and uncomment ones in use

- $ vi scumblr.rb

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
	- Paste the API key into the "config.google_developer_key" field in /Scumblr/config/scumblr.rb

##### Build your custom search engine
- Go to: https://cse.google.com/cse/all
- Click 'New search engine' on the left
	- Type in 'www.google.com' in Sites to search
	- Name your search engine: 'scumblr-google-search'
- Under 'Edit search engine', select your search engine, click Setup
	- Click on 'Search engine ID', copy this text
	- Paste the ID into "config.google_cx" field in /Scumblr/config/scumblr.rb
	- Click on 'Public URL' and turn off
	- Enable 'Image Search'
	- Disable 'Speech Input'
- Under 'Sites to search', change the box to "Search the entire web but emphasize included sites"
	- Delete www.google.com from sites if you want, it is unnessary
	- Click Update
	- The remaining fields in /Scumblr/config/scumblr.rb are the App name and version = '1.0'
	
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
- Copy 'App ID' and 'App Secret' into cooresponding fields in /Scumblr/config/scumblr.rb
- Facebook Search Provider is configured!


### Twitter Search Provider
- Go to: https://dev.twitter.com/apps/new
- Enter Application Name, Description, and Website (use github.com). Leave callback URL blank
- Accept the TOS
- Under the Keys and Access Tokens Tab:
	- You will generate and copy keys/secrets into the fields in /Scumblr/config/scumblr.rb
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
	- Paste the API key into the "config.youtube_developer_key" field in /Scumblr/config/scumblr.rb
	- The remaining fields in /Scumblr/config/scumblr.rb are the App name = 'youtube' and version = 'v3'
- YouTube Search Provider is configured 


# Sketchy Integration
- TODO


# Slack Integration
- TODO


# MISC
- To ban all spiders from the entire site uncomment the User-Agent and Disallow lines

$ vi /Scumblr/public/robots.txt







