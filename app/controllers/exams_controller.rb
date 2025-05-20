class ExamsController < ApplicationController

    include NavigationHelper

    before_action :authorize, except: [ :json, :post ]

    before_action :prepare_exam_context, only: [ :json, :post ]

    skip_before_action :verify_authenticity_token, only: [ :post ]

    layout "sidebar"

    def index
        # get all exams from config that may be submitted
        # allow student to choose one and start
        if Settings.registration_phase == "exam"
            @exams = Exam.joins(:pset).order(:name).where(current_exam: true)
            render layout: "blank" and return
        end
        @exams = Exam.joins(:pset).order(:name)
        # only show subselection of active exams for non-admins
        @exams = @exams.where(locked: false) unless current_user.admin?
    end

    # student starts a new exam session - this can also be a resumption
    def create
        @exam = Exam.includes(:pset).find(params[:id])

        # create submit for this exam for this student (if needed!)
        @submit = Submit.find_or_create_by!(pset: @exam.pset, user: current_user)

        # we do not want >1 simultaneous sessions, which is why we
        # create a new submit code each time
        code = SecureRandom.hex(32)
        @submit.update(exam_code: code)

        # redirect to external editor with post url and code
        params = "url=#{json_exam_url}&code=#{code}"
        redirect_to "#{Settings.exam_base_url}?#{params}", allow_other_host: true
    end

    def json
        headers["Access-Control-Allow-Origin"] = "*"

        config = {
            course_name: Course.short_name,
            exam_name: @submit.user.name, # @exam.pset.name.humanize,
            postback: post_exam_url,
            tabs: @exam.config["files"]&.map { |f| [ f["name"], f["template"] ] }.to_h,
            hidden_tabs: @exam.config["hidden_files"]&.map { |f| [ f["name"], f["template"] ] }.to_h,
            buttons: @exam.config["buttons"]&.map { |f| [ f["name"], f["commands"] ] }.to_h
        }

        # if submitted previously, copy older contents into config
        # this is particularly useful if an exam has to be resumed from
        # another computer - which does not have a local cache of the files
        # if the local cache is present, that will take precedence anyway
        config[:tabs].merge! @submit.all_files.map { |x| [ x[0], x[1].download ] }.to_h

        # only allow initializing editor as long as no grade was created for this submit
        unless exam_is_open_for_user?
            config[:locked] = true
            config[:tabs] = nil
            config[:hidden_tabs] = nil
            config[:buttons] = nil
        end

        render json: config
    end

    # allow posting new files for current exam
    def post
        headers["Access-Control-Allow-Origin"] = "*"

        # only allow updates as long as no grade was created for this submit
        if exam_is_open_for_user?
            @submit.files = params[:files].values if params[:files].present?
            @submit.update(submitted_at: Time.zone.now)
            render status: :accepted, plain: "OK" and return
        end

        render status: :locked, plain: "locked"
    end

    private

    def prepare_exam_context
        @exam = Exam.includes(:pset).find(params[:id])
        @submit = Submit.includes(:user).find_by(pset: @exam.pset, exam_code: params[:code])

        if params[:code].blank? || @submit.blank?
            render status: :bad_request, plain: "what you sent is invalid" and return
        end

        if ip_check_failed?(@submit)
            render status: :precondition_failed, plain: "wrong ip" and return
        end
    end

    def ip_check_failed?(submit)
        Settings.registration_phase == "exam" && submit.user.last_known_ip != request.remote_ip
    end

    def exam_is_open_for_user?
        @submit.user.admin? || (@exam.allow_taking? && @submit.grade.blank? && !@submit.locked)
    end
end
