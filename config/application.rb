require_relative 'boot'

# require 'rails/all'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
# require 'action_cable/engine'
# require 'action_mailbox/engine'
# require 'action_text/engine'
# require 'rails/test_unit/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CourseSite
	class Application < Rails::Application
		# Initialize configuration defaults for originally generated Rails version.
		config.load_defaults 6.1

		# Settings in config/environments/* take precedence over those specified here.
		# Application configuration can go into files in config/initializers
		# -- all .rb files in that directory are automatically loaded after loading
		# the framework and any gems in your application.
		config.time_zone = 'Amsterdam'
		config.action_mailer.smtp_settings = { address: ENV["MAILER_ADDRESS"], domain: ENV["MAILER_DOMAIN"] }
		config.active_storage.variant_processor = :vips
		config.active_job.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new \
			min_threads: 1,
			max_threads: 1,
			idletime: 600.seconds
	end
end
