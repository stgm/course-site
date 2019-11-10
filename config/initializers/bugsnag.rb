Bugsnag.configure do |config|
	config.api_key = ENV['BUGSNAG_ID']
	config.notify_release_stages = ['production']
	config.ignore_classes << ActionController::RoutingError
end
