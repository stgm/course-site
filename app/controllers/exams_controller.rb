class ExamsController < ApplicationController

    include NavigationHelper

    before_action :authorize, except: [:json, :post]
    skip_before_action :verify_authenticity_token, only: [:post]

    layout 'sidebar'

    def index
        # get all exams from config that may be submitted
        # allow student to choose one and start
        @exams = Exam.joins(:pset).includes(pset: :submits).order(:name)
        @exams = @exams.where(locked: false) if !current_user.admin?
        if Settings.registration_phase == 'exam'
            render layout: 'blank' and return
        end
    end

    def create
        @exam = Exam.includes(:pset).find(params[:id])

        # create submit for this exam for this student (if needed!)
        @submit = Submit.find_or_create_by!(pset: @exam.pset, user: current_user)

        # create a (new) submit code and add to submit
        code = SecureRandom.hex(32)
        @submit.update(exam_code: code)

        # redirect to external editor with post url and code
        params = "url=#{json_exam_url}&code=#{code}"
        if Rails.env.development?
            redirect_to "http://localhost:8009/exam.html?#{params}"
        else
            redirect_to "https://ide.proglab.nl/exam.html?#{params}", allow_other_host: true
        end
    end

    def json
        headers['Access-Control-Allow-Origin'] = '*'

        # get exam config, including files and base contents
        @exam = Exam.includes(:pset).find(params[:id])
        @submit = Submit.where(pset: @exam.pset, exam_code: params[:code]).first

        if params[:code].blank? || @submit.blank?
            render status: :bad_request, plain: 'what you sent is invalid' and return
        end

        if Settings.registration_phase == 'exam' && @submit.user.last_known_ip != request.remote_ip
            render status: :precondition_failed, plain: 'wrong ip' and return
        end

        config = {
            course_name: Course.short_name,
            exam_name: @submit.user.name, #@exam.pset.name.humanize,
            postback: post_exam_url,
            tabs: @exam.config['files']&.map{|f| [f['name'], f['template']] }.to_h,
            buttons: @exam.config['buttons']&.map{|f| [f['name'], f['commands']] }.to_h
        }

        # if submitted previously, copy older contents into config
        # this is particularly useful if an exam has to be resumed from
        # another computer - which does not have a local cache of the files
        # if the local cache is present, that will take precedence anyway
        config[:tabs].merge! @submit.all_files.map{|x| [x[0], x[1].download]}.to_h

        if @exam.locked || @submit.grade.present? || @submit.locked
            config[:locked] = true
            config[:tabs] = nil
            config[:buttons] = nil
        end

        render json: config
    end

    def post
        headers['Access-Control-Allow-Origin'] = '*'

        # allow posting new files for current exam
        @exam = Exam.includes(:pset).find(params[:id])

        # but only with the submit code
        @submit = Submit.where(pset: @exam.pset, exam_code: params[:code]).first
        if @submit.blank?
            render status: :not_found, plain: 'your data is invalid' and return
        end

        # and, when in exam mode, only if the current ip matches login ip
        if Settings.registration_phase == 'exam' && @submit.user.last_known_ip != request.remote_ip
            render status: :precondition_failed, plain: 'wrong ip' and return
        end

        # only allow updates as long as no grade was created for this submit
        if !@exam.locked && @submit.grade.blank? && !@submit.locked
            @submit.files.purge
            permitted = params.permit(files: {})
            permitted[:files].each do |filename, attachment|
                @submit.files.attach(io: attachment.open, filename: filename)
            end
            @submit.update(submitted_at: DateTime.now)
            render status: :accepted, plain: 'OK' and return
        end

        render status: :locked, plain: 'locked'
    end

    private

end
