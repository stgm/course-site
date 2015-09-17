base_url = ENV['CAS_BASE_URL']
fake_user = ENV['CAS_FAKE_USER']
validate_url = "#{base_url}serviceValidate"

if base_url.present?
	CASClient::Frameworks::Rails::Filter.configure(
		cas_base_url: base_url,
		validate_url: validate_url
	)
end

if fake_user.present?
	CASClient::Frameworks::Rails::Filter.fake(fake_user)
end
