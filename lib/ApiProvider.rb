module ApiProvider
	
	@@api_token = ENV['COURSESITE_API_TOKEN']

	def self.available?
		return @@api_token.present?
	end
	
	def self.check_token(token)
		return @@api_token == token
	end
		
end
