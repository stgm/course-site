# require 'api_provider'

class ApiController < ApplicationController

    skip_before_action :verify_authenticity_token
	before_action :restrict_access, only: :reload
	
	def reload
		CourseLoader.new.run
		render text:''
	end
	
	def current_longest_waiting_time
		if longest = Hand.waiting.order("created_at desc").first
			seconds = (Time.now - longest.created_at).to_i
			render json: {
				"postfix": "minutes",
				"color": "green",
				"data": {
					"value": seconds / 60
				}
			}
		else
			render json: {
				"postfix": "minutes",
				"color": "green",
				"data": {
					"value": 0
				}
			}
		end
	end

	private
	
	def restrict_access
		request.body.rewind
		payload_body = request.body.read
		verify_signature(payload_body)
	end

	def verify_signature(payload_body)
		# TODO ignore request if Settings.webhook_secret is not set
		secret = Settings.webhook_secret
		signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
		render text:'', status:500 unless request.env['HTTP_X_HUB_SIGNATURE'].present? && Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
		#halt 500, "Signatures didn't match!" unless 
	end
	
end
