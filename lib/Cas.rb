module Cas
	
	@@base_url = ENV['CAS_BASE_URL']
	@@fake_user = ENV['CAS_FAKE_USER']

	def self.available?
		return @@base_url.present?
	end
	
	def self.will_fake?
		return @@fake_user.present?
	end
	
	def self.base_url
		return @@base_url
	end
	
	def self.validate_url
		return "#{@@base_url}serviceValidate"
	end
	
	def self.fake_username
		return @@fake_user
	end
	
end
