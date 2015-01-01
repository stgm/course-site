require 'course'
require 'api_provider'

class ApiController < ApplicationController

	before_action :restrict_access
	
	def reload
		Course.reload
		render json: nil
	end

	private
	
	def restrict_access
		request.body.rewind
		payload_body = request.body.read
		verify_signature(payload_body)
	end

	def verify_signature(payload_body)
		secret = Settings.webhook_secret
		signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
		render text:'no' unless request.env['HTTP_X_HUB_SIGNATURE'].present? && Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
		#halt 500, "Signatures didn't match!" unless 
	end
	
end
