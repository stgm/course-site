class AutoCheckUploader
	
	def self.enabled?
		true
	end
	
	def initialize(attachments, config, host)
		@attachments = attachments
		@config = config
		@host = host
	end
	
	def start
		server = RestClient::Resource.new(
			"https://agile008.science.uva.nl/#{@config['tool']}",
			verify_ssl: OpenSSL::SSL::VERIFY_NONE)
	
		begin
			args = {
				file: @attachments.zipped,
				password: "martijndoeteenphd",
				webhook: "https://#{@host}/api/check_result/do",
				multipart: true
				# and add slug/repo/args from the config file
			}.merge(@config.slice('slug', 'repo', 'args'))
			
			response = server.post(args)
			Rails.logger.debug JSON.parse(response.body)['id']
			return JSON.parse(response.body)['id']
		rescue RestClient::ExceptionWithResponse => e
			Rails.logger.debug e.response
		end
		
	end

end
