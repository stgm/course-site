class ExamsController < ApplicationController

    include NavigationHelper

    before_action :authorize, except: [:json, :post]
    skip_before_action :verify_authenticity_token, only: [:post]

    layout 'sidebar'

    def index
        # get all exams from config that may be submitted
        # allow student to choose one and start
        @exams = Pset.includes(:submits).where(name: current_schedule.grading_config.exams)
    end

    def create
        @exam = Pset.find(params[:id])

        # create submit for this exam for this student (if needed!)
        @submit = Submit.find_or_create_by!(pset: @exam, user: current_user)

        # create a (new) submit code and add to submit
        code = SecureRandom.hex
        @submit.update(exam_code: code)

        # redirect to external editor with post url and code
        params = "url=#{json_exam_url}&code=#{code}"
        if Rails.env.development?
            redirect_to "http://localhost:8009/?#{params}"
        else
            redirect_to "https://uvapl.github.io/examide/?#{params}", allow_other_host: true
        end
    end

    def json
        headers['Access-Control-Allow-Origin'] = '*'

        # get exam config, including files and base contents
        @exam = Pset.find(params[:id])
        @submit = Submit.where(pset: @exam, exam_code: params[:code]).first

        if params[:code].blank? || @submit.blank?
            render status: :bad_request, plain: 'what you sent is invalid' and return
        end

        config = {
            course_name: Course.long_name,
            exam_name: @exam.name.humanize,
            postback: post_exam_url,
            tabs: @submit.grading_config['files'].map{|k,v| v}.inject { |all, h| all.merge(h) }
        }

        config['locked'] = true if !@submit.grade.blank? or @submit.locked

        render json: config
    end

    def post
        headers['Access-Control-Allow-Origin'] = '*'

        # allow posting new files for current exam
        @exam = Pset.find(params[:id])

        # but only with the submit code
        @submit = Submit.where(pset: @exam, exam_code: params[:code]).first

        if @submit.blank?
            render status: :not_found, plain: 'your data is invalid' and return
        end

        # only allow updates as long as no grade was created for this submit
        if @submit.grade.blank? && !@submit.locked
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
