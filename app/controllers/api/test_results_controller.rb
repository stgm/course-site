class Api::TestResultsController < ApplicationController

    skip_before_action :verify_authenticity_token
	before_action :restrict_access, only: :create
	
	def create
		# post request with application/json type
		#
		# [
		# 	{
		#		'id': 1,
		# 		'user_id': '9829271',
		# 		'test': 'test A',
		#		'version': 'v1',
		# 		'passed': true,
		# 		'date': '2020-02-22T12:47:57+01:00',
		# 		'grader': 'Martijn Stegeman'
		# 	}, ...
		# ]
		#
		# returns array with ids of results that were successfully registered
		
		succeeded = []
		
		request['results'].each do |result|
			user = User.find_by_login(result['user_id'])
			pset = Pset.find_by_name(result['test'])
			if user.present? && pset.present?
				submit = Submit.where(user: user, pset: pset).first_or_initialize
				submit.submitted_at = DateTime.now
				submit.save
				
				grade = submit.grade || submit.create_grade
				grade.subgrades['passed'] = result['passed'] && -1 || 0
				grade.updated_at = result['date']
				grade.notes ||= '' #initialize string if needed
				grade.notes << "#{result['date']}, #{result['grader']}, version: #{result['version']}, passed: #{result['passed']}\n"
				grade.status = Grade.statuses['published']
				grade.grader = User.admin.first

				saved = grade.save
				succeeded << result['id'] if saved
			end
		end
		
		render json: succeeded
	end
	
	private
	
	def restrict_access
		unless ['127.0.0.1', '::1'].include? request.remote_ip
			request.body.rewind
			payload_body = request.body.read
			verify_signature(payload_body)
		end
	end

	def verify_signature(payload_body)
		secret = Settings.webhook_secret
		signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
		render head: :internal_server_error unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
	end
	
end
