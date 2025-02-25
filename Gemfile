source "https://rubygems.org"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~>8.0.1"

# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"

# Use Puma as the app server
gem "puma", ">= 5.0"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
# gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development do
    gem "web-console"
    gem "brakeman", require: false
    gem "rubocop-rails-omakase", require: false
end

group :production do
    gem "mini_racer"
    gem "exception_notification", github: "smartinez87/exception_notification", ref: "26441fb"
    gem "azure-storage-blob", "~> 2.0", require: false # active storage client
    gem "pg"
end

# assets
gem "sprockets-rails"
gem "dartsass-sprockets"

# slug generator
gem "friendly_id"

# connectivity
gem "git", "1.13.0"  # git for ingesting course materials
gem "rack-cas"       # login system
gem "openid_connect"
gem "curb"           # webdav client for uploading archival files
gem "rest-client"    # for sending submits to the autocheck server

# manages settings in database
gem "rails-settings-cached"

# scheduled email sending for grades
gem "rufus-scheduler"

# content
gem "kramdown"
gem "asciidoctor"
gem "front_matter_parser"
gem "katex", "~> 0.10.0"
gem "kramdown-math-katex"

# XLSX generation
gem "rubyzip", "~> 2.3.0", require: "zip"
gem "caxlsx_rails"

# front-end
gem "bootstrap", "~> 5.3.3"
# gem "autoprefixer-rails", "~> 10.2.5"
gem "coderay"
gem "groupdate"
gem "importmap-rails"
gem "stimulus-rails"
gem "turbo-rails"

# used by ActiveStorage
gem "image_processing", "~> 1.12"
gem "active_storage-send_zip"
