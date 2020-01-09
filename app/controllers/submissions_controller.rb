class SubmissionsController < ApplicationController
	
	before_action :load_pset, :validate_attachment_size
	
	def create
		collect_attachments
		# begin
			upload_attachments_to_dropbox if Dropbox.available?
		# rescue
			# redirect_back(fallback_location: '/', alert: "There was a problem uploading your submission! Please try again. If the problem persists, contact your teacher.".html_safe ) and return
		# end
		upload_files_to_check_server if can_do_auto_check?
		record_submission
		redirect_back fallback_location: '/'
	end
	
	private
	
	def load_pset
		@pset = Pset.find(params[:pset_id])
	end
	
	def validate_attachment_size
		request.content_length < 10000000
	end
	
	def collect_attachments
		@attachments = Attachments.new(params.permit(f: {})[:f].to_h)
		
		# we don't actually have forms in our sites at this point
		# if params[:a]
		# 	form = params[:a].each do |key, value|
		# 		"#{key}\n\n" + "#{value}\n\n"
		# 	end
		# 	@attachments.add("form.txt", form)
		# end
		
		# params[:notes] is historically also interesting
		# # compose info.txt file contents
		# info = "student_login_id = " + user
		# info += ("\nname = " + name) if name
		# info += "\n\n"
		# info += notes if notes
		
		puts @attachments.inspect
	end
	
	def upload_attachments_to_dropbox
		@submit_folder_name = @pset.name + "__" + Time.now.to_i.to_s

		submission_path = File.join(
			'/',
			'Submit',                      # /Submit
			Settings.dropbox_folder_name,  # /course name
			current_user.login_id,         # /student ID
			@submit_folder_name)           # /mario__21981289
		
		uploader = DropboxUploader.new(submission_path)
		uploader.upload(@attachments.all)
	end
	
	def can_do_auto_check?
		AutoCheckUploader.enabled? && @pset.config['check'].present?
	end
	
	def upload_files_to_check_server
		@token = AutoCheckUploader.new(@attachments.zipped, @pset.config['check'], request.host).start
	end
		
	def record_submission
		submit = Submit.where(user: current_user, pset: @pset).first_or_initialize
		submit.record(
			used_login: current_user.login_id,
			dropbox_folder_name: @submit_folder_name,
			url: params[:url],
			attachments: @attachments,
			check_token: @token)
	end
	
end
