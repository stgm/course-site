#
# Configure CAS authentication
#

# "secret" URLs must be configured in enviroment variables
base_url = ENV['CAS_BASE_URL']
fake_user = ENV['CAS_FAKE_USER']

validate_url = "#{base_url}serviceValidate"

# configure with real server URLs
if base_url.present?
	CASClient::Frameworks::Rails::Filter.configure(cas_base_url: base_url, validate_url: validate_url)
end

# optionally, configure fixed user login for testing purposes (logout won't be possbible)
if fake_user.present?
	if not base_url.present?
		CASClient::Frameworks::Rails::Filter.configure(cas_base_url: "", validate_url: "")
	end
	CASClient::Frameworks::Rails::Filter.fake(fake_user)
end
