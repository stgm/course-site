class SubmissionsController < ApplicationController

	before_action :authorize
	before_action :load_pset, :validate_attachment_size, only: [ :create ]

	layout 'sidebar'

	# Presents an overview of all submissions for the current user.
	def index
		@student = User.includes(:hands, :notes).find(current_user.id)
		@items = @student.items
		raise ActionController::RoutingError.new('Not Found') if @items.empty?

		# overview table
		@overview_config = GradingConfig.overview_config
		@grades_by_pset = @student.submits.joins(:grade).includes(:grade, :pset).where(grades: { status: Grade.statuses[:published] }).to_h { |item| [item.pset.name, item.grade] }

		@title = t(:submissions)
	end

	# Accepts a submission coming from a course page.
	def create
        # begin
			collect_attachments
			upload_attachments_to_webdav  if should_upload_to_webdav?
			upload_files_to_check_server  if should_perform_auto_check?
			upload_files_to_plag_server   if should_upload_to_plag_server?
			record_submission
			redirect_back fallback_location: '/'
        # rescue => e
        #     redirect_back(
        #         fallback_location: '/',
        #         alert: "There was a problem uploading your submission! Please try again. " \
        #                "If the problem persists, contact your teacher.<br><pre>#{e.message}</pre><br><pre>#{e.backtrace.first}</pre>")
        # end
	end

	# Shows automatic check feedback for a single submission.
	def feedback
		submit = current_user.submits.find(params[:submission_id])
		@formatted_feedback = submit.formatted_auto_feedback
		@formatted_feedback = '(no data)' if @formatted_feedback.blank?
		render layout: 'modal'
	end

	private

	def load_pset
		@pset = Pset.find(params[:pset_id])
	end

	def validate_attachment_size
		unless request.content_length < 10000000
			redirect_back(
				fallback_location: '/',
				alert: "Your submission contains files that are too large! Please try again. ")
		end
	end

	def collect_attachments
		@attachments = Attachments.new(params.permit(f: {})[:f].to_h)
		@form_contents = params.permit(form: {})[:form].try(:to_hash)
	end

	def upload_attachments_to_webdav
		@submit_folder_name ||= @pset.name + "__" + Time.now.to_i.to_s

		submission_path = File.join(
		'/',
		Settings.archive_base_folder,    # /Submit
		Settings.archive_course_folder,  # /course name
		current_user.defacto_student_identifier, # /student ID
		@submit_folder_name)             # /mario__21981289

		uploader = Submit::Webdav::Uploader.new(submission_path)
		uploader.upload(@attachments.all)
	end

	def should_upload_to_webdav?
		Submit::Webdav::Client.available?
	end

	def should_perform_auto_check?
		Submit::AutoCheck::Sender.enabled? && @pset.config['check'].present?
	end

	def upload_files_to_check_server
		@token = Submit::AutoCheck::Sender.new(@attachments.zipped, @pset.config['check'], request.host).start
	end

    def should_upload_to_plag_server?
        !current_user.staff? && @pset.config['plag'].present?
    end

    def upload_files_to_plag_server
        uploader = Submit::Plag::Uploader.new(@pset.config['plag'].merge({ student: current_user.defacto_student_identifier }))
        uploader.upload(@attachments.zipped)
        uploader.close
    end

	def record_submission
		submit = Submit.where(user: current_user, pset: @pset).first_or_initialize
		submit.record(
			used_login: current_user.defacto_student_identifier,
			archive_folder_name: @submit_folder_name,
			url: params[:url],
			attachments: @attachments,
			form_contents: @form_contents,
			check_token: @token)
	end

end
