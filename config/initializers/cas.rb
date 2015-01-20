require 'lib/cas.rb'

CASClient::Frameworks::Rails::Filter.configure(
	cas_base_url: Cas.base_url,
	validate_url: Cas.validate_url
) if Cas.available?

CASClient::Frameworks::Rails::Filter.fake(Cas.fake_username) if Cas.will_fake?
