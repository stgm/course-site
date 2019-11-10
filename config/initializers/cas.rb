#
# Configure CAS authentication
#

# "secret" URLs must be configured in enviroment variables
base_url = ENV['CAS_BASE_URL']
validate_url = "#{base_url}serviceValidate"

# configure with real server URLs
if base_url.present?
	Rails.application.configure do
		config.rack_cas.server_url = base_url
	end

end
