class Submit::AutoCheck::Sender
	
	def self.enabled?
		ENV['CHECK_SERVER_URL'].present? && ENV['CHECK_SERVER_SECRET'].present?
	end
	
	def initialize(attachments, config, host)
		@server_url = ENV['CHECK_SERVER_URL']
		@server_secret = ENV['CHECK_SERVER_SECRET']
		
		@zipped_attachments = attachments
		@config = config
		@callback_url = host
	end
	
	def start
		endpoint = RestClient::Resource.new(
			URI.join(@server_url, @config['tool']).to_s,
			verify_ssl: OpenSSL::SSL::VERIFY_NONE)
	
		begin
			opts = {
				file: @zipped_attachments,
				password: @server_secret,
				webhook: @callback_url,
				multipart: true
			}
			# and add slug/repo/args from the config file
			config_opts = @config.slice('slug', 'repo', 'args')
			
			response = endpoint.post(opts.merge(config_opts))
			return JSON.parse(response.body)['id']
		rescue RestClient::ExceptionWithResponse => e
			return false
		end
		
	end

end
