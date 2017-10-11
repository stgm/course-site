Bugsnag.configure do |config|
	config.api_key = ENV['BUGSNAG_ID']
	config.ignore_classes << ActionController::RoutingError
end
