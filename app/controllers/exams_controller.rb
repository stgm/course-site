class ExamsController < ApplicationController

    before_action :authorize, except: [:json, :post]
    skip_before_action :verify_authenticity_token, only: [:post]

    layout 'sidebar'

    def index
        # get all exams from config that may be submitted
        # allow student to choose one and start
        @exams = Pset.where(name: GradingConfig.exams)
    end

    def create
        @exam = Pset.find(params[:id])

        # create submit for this exam for this student (if needed!)
        @submit = Submit.find_or_create_by!(pset: @exam, user: current_user)

        # create a (new) submit code and add to submit
        code = SecureRandom.hex
        @submit.update(exam_code: code)

        # redirect to external editor with post url and code
        redirect_to "http://localhost:8009/?url=#{json_exam_url}&code=#{code}", allow_other_host: true
    end

    def json
        # get exam config, including files and base contents
        @exam = Pset.find(params[:id])

        headers['Access-Control-Allow-Origin'] = '*'

        render json: {
            postback: post_exam_url,
            tabs: @exam.config['files'].map{|k,v| v}.inject { |all, h| all.merge(h) }
        }
    end

    def post
        headers['Access-Control-Allow-Origin'] = '*'

        # allow posting new files for current exam
        @exam = Pset.find(params[:id])

        # but only with the submit code
        @submit = Submit.where(pset: @exam, exam_code: params[:code]).first

        # only allow updates as long as no grade was created for this submit
        if @submit.grade.blank? && !@submit.locked
            @submit.files.purge
            permitted = params.permit(files: {})
            permitted[:files].each do |filename, attachment|
                @submit.files.attach(io: attachment.open, filename: filename)
            end
            render status: :accepted, plain: 'OK' and return
        end

        render status: :locked, plain: 'locked'
    end

    private

end
