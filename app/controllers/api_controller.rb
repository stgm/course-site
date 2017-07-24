require 'api_provider'

class ApiController < ApplicationController

    skip_before_filter :verify_authenticity_token
	before_action :restrict_access
	
	def reload
		CourseLoader.new.run
		render text:''
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
		render text:'', status:500 unless request.env['HTTP_X_HUB_SIGNATURE'].present? && Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
		#halt 500, "Signatures didn't match!" unless 
	end
	
end
