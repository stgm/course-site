source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>7.0.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

# Use Puma as the app server
gem 'puma', '~> 5.0'

group :development do
    # shut up icon requests
    gem 'listen'
    gem 'quiet_safari'
    gem 'web-console'
end

group :production do
    gem 'bugsnag'
end

# assets
gem 'sprockets-rails'
gem 'sass-rails'
gem 'autoprefixer-rails', '~> 10.2.5'

# slug generator
gem 'friendly_id'

# connectivity
gem 'git'         # git for ingesting course materials
gem 'rack-cas'    # login system
gem 'curb'        # webdav client for uploading archival files
gem 'rest-client' # for sending submits to the autocheck server

# manages settings in database
gem 'rails-settings-cached'

# scheduled email sending for grades
gem 'rufus-scheduler'

# content
gem 'kramdown'
gem 'asciidoctor'
gem 'front_matter_parser'

# XLSX generation
gem 'rubyzip', '~> 2.3.0', require: 'zip'
gem 'caxlsx_rails'

# front-end
gem 'bootstrap', '~> 5.0.0'
gem 'coderay'
gem 'groupdate'
gem 'stimulus-rails', '~> 0.2.4'
gem 'turbo-rails'

# used by ActiveStorage to get image previews
gem 'image_processing', '~> 1.2'
