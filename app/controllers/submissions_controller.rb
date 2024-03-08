class SubmissionsController < ApplicationController

    include NavigationHelper
    include ActiveStorage::SendZip

    before_action :authorize
    before_action :load_pset, :check_permission_to_submit, :validate_attachment_size, only: [ :create ]

    layout 'sidebar'

    # Presents an overview of all submissions for the current user.
    def index
        @student = User.includes(:hands, :notes).find(current_user.id)
        @items = @student.items
        raise ActionController::RoutingError.new('Not Found') if @items.empty?

        # overview table
        @overview_config = current_schedule.grading_config.overview_config
        @grades_by_pset = @student.submits.joins(:grade).includes(:grade, :pset).where(grades: { status: Grade.statuses[:published] }).to_h { |item| [item.pset.name, item.grade] }

        @title = t(:submissions)
    end

    # Accepts a submission coming from a course page.
    def create
        collect_attachments
        upload_attachments_to_webdav  if should_upload_to_webdav?
        upload_files_to_check_server  if should_perform_auto_check?
        record_submission
        upload_files_to_plag_server   if should_upload_to_plag_server?
        redirect_back fallback_location: '/'
    end

    # Shows automatic check feedback for a single submission.
    def feedback
        submit = current_user.submits.find(params[:submission_id])
        @formatted_feedback = submit.formatted_auto_feedback
        @formatted_feedback = '(no data)' if @formatted_feedback.blank?
        render layout: 'modal'
    end

    def download
        submit = current_user.submits.find(params[:submission_id])
        if submit.files.count > 1
            send_zip submit.files, filename: "#{submit.pset.name.dasherize}-#{submit.user.name.parameterize}-#{submit.submitted_at.to_fs(:number)}.zip"
        else
            redirect_to rails_storage_proxy_path(submit.files.first, disposition: 'attachment')
        end
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

    def check_permission_to_submit
        if not Submit.find_or_initialize_by(user: current_user, pset: @pset).allow_new_submit?
            redirect_back(
            fallback_location: '/',
            alert: "Sorry, you can't submit this problem. Consult your teacher if you think this is in error.")
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
        Submit::AutoCheck::Sender.enabled? && @pset.submit_config['check'].present?
    end

    def upload_files_to_check_server
        @attachments.zipped do |zip|
            @token = Submit::AutoCheck::Sender.new(zip, @pset.submit_config['check'], api_check_result_do_url).start
        end
    end

    def should_upload_to_plag_server?
        !current_user.staff? && @pset.submit_config['plag'].present?
    end

    def upload_files_to_plag_server
        uploader = Submit::Plag::Uploader.new(@pset.submit_config['plag'].merge({ student: current_user.defacto_student_identifier }))
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
