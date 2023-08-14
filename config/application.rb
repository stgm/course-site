require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CourseSite
    class Application < Rails::Application
        # Initialize configuration defaults for originally generated Rails version.
        config.load_defaults 7.0

        # Configuration for the application, engines, and railties goes here.
        #
        # These settings can be overridden in specific environments using the files
        # in config/environments, which are processed later.
        #
        # config.time_zone = "Central Time (US & Canada)"
        # config.eager_load_paths << Rails.root.join("extras")
        config.time_zone = 'Amsterdam'
        config.action_mailer.smtp_settings = {
            address: ENV["MAILER_ADDRESS"],
            domain: ENV["MAILER_DOMAIN"],
            port: 465,
            user_name: ENV["MAILER_USER"],
            password: ENV["MAILER_PASS"]
        }

        config.active_record.yaml_column_permitted_classes = [HashWithIndifferentAccess]

        # Can be deleted after load_defaults 7.0
        config.active_storage.variant_processor = :vips

        config.active_job.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new \
            min_threads: 1,
            max_threads: 1,
            idletime: 600.seconds
    end
end
