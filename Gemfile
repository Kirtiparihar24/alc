source "http://rubygems.org"
# bundle install --without=development
# bundler-0.9.25 gem required to be installed first

#main group
gem "rails", "2.3.14"					# actionmailer, actionpack, activerecord, activeresource, activesupport, rack, rake
gem "devise", "1.0.11"
gem "cancan","1.4.0"					# updated - Working
gem "warden"
gem "pg", "0.9.0"						  # 0.11.0 (03122011)
gem "passenger"							  # 3.0.11 (03122011) -working App Server
gem "thinking-sphinx", "1.3.18"			# 1.3.21 (03122011)Search Adapter
gem "paperclip"							  # File Uploads-builder, i18n, activemodel, arel, tzinfo
gem "mail","2.2.1"						# Emails updated - not tested	# mime-types, polyglot, treetop
gem "bounce-email"
gem "will_paginate", '~> 2.3.16'
gem "breadcrumbs_on_rails","1.0.1"


##file/API readers for importing 
gem "spreadsheet"						# ruby-ole
gem "google-spreadsheet-ruby"			# updated - not tested	# hpricot, oauth
gem "fastercsv"			        		# updated - not tested
gem "flexible_csv"						# fastercsv
gem "soap4r"							# httpclient

## for rss feeds
gem "feedzirra"							# nokogiri, sax-machine, curb, builder, loofah
gem "nokogiri"

gem 'i18n', "=0.4.0"
gem "jammit"

## for pdf generation
gem "acts_as_flying_saucer","~>1.0.0"
gem "tidy_ffi"
gem "nailgun"

gem "pdfkit"
gem "prawn", "0.6.3"					# updated - not Working 	# prawn-core, prawn-layout, prawn-security

##For backgrounding and i18n
gem "redis", "~> 2.2.0", :require => ["redis/connection/hiredis", "redis"] #2.2.2 (03122011)
gem "hiredis", "~> 0.3.1" 				#0.4.1 (03122011)
gem "resque"


#=========================================================
gem "rubyzip"
gem "roo", "1.9.2"						# updated - not tested
gem "ezcrypto"
gem "whenever", "0.4.1"		    		# updated - not tested	# json_pure, rubyforge, hoe, chronic
gem "erubis","2.6.6"					# abstract
gem "httparty", "0.5.2"					# crack
gem "responds_to_parent"
gem "json"

gem "acts_as_audited"
gem "postgres_sequence_support"

gem "ohm"
gem "liquid"
gem "SystemTimer"             #?
gem "jrails"
#========================================================


group :development do

  #Debugging
  gem "ruby-debug"
  gem "ruby-debug-ide"
  gem "pry"
  gem "wirble"
  #gem  "hirb"

  #performance analysis  
  #gem "newrelic_rpm"
  #gem "rails_best_practices"
  #gem "rack-bug"
  #gem "metric_fu"
  #gem "oink"

  gem "ready_for_i18n"					# helps while i18n development

  #cleaners
  #gem "bullet"                          #A rails plugin to kill N+1 queries and unused eager loading
  #gem "deadweight" 						#A coverage tool for finding unused CSS

  gem "thin"                            #better/ faster app server than outdated webrick and mongrel for development env and also supports debugging
  gem "mongrel"

end



