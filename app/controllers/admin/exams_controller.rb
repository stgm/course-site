class Admin::ExamsController < ApplicationController

    before_action :authorize
    before_action :require_admin

    layout "navbar"

    def index
        return head(:not_found) if Exam.none?

        # get all exams from config that may be submitted
        # allow student to choose one and start
        @exams = Exam.includes(:pset).order("psets.name")
    end

    # exam is in session, show statistics and progress
    def show
        @exam = Exam.find(params[:id])
        @students = @exam.active_submits
        @longer_ago = @exam.stale_submits

        # the room map is a page of its own; the two are tabs on each other,
        # and whichever was used last is where a bare link lands
        if params[:view].blank? && session[:exam_view] != "list"
            return redirect_to admin_exam_room_path(@exam)
        end
        session[:exam_view] = "list"
    end

    # edit exam templates + buttons
    def edit
        @exam = Exam.find(params[:id])
        render layout: 'modal'
    end

    # either save templates or some setting for the exam
    def update
        @exam = Exam.find(params[:id])

        permitted = params.expect(exam: [ :locked, :eval_code, config: {} ])

        if params[:commit] == 'Save templates' && permitted[:config].present?
            permitted[:config][:files]        = permitted[:config][:files].select { |i| i["name"].present? }
            permitted[:config][:hidden_files] = permitted[:config][:hidden_files].select { |i| i["name"].present? }
            permitted[:config][:buttons]      = permitted[:config][:buttons].select { |i| i["name"].present? }
        end

        if @exam.update(permitted)
            if params[:commit] == 'Save templates'
                redirect_to edit_admin_exam_path
            else
                redirect_to admin_exams_path
            end
        else
            render :show
        end
    end

    def toggle
        @exam = Exam.find(params[:id])
        p = params.expect(exam: [ :locked ])
        if @exam.update(p)
            head :ok
        end
    end

    def toggle_student
        @exam = Exam.find(params[:id])
        @submit = @exam.pset.submits.find(params[:submit_id])
        p = params.expect(submit: [ :locked ])
        return unless @submit.update(p)

        # From the room map the table itself has to change: a locked student
        # gets a lock and stops being warned about. The list has nothing to
        # redraw, so it stays a bare ok.
        if params[:view] == "room"
            redirect_to admin_exam_room_path(@exam, phase: params[:phase])
        else
            head :ok
        end
    end

    def reset_student_ip
        exam = Exam.find(params[:id])
        submit = exam.pset.submits.find(params[:submit_id])
        submit.user.update(last_known_ip: nil)

        if params[:view] == "room"
            redirect_to admin_exam_room_path(exam, phase: params[:phase])
        else
            redirect_to admin_exam_path(exam)
        end
    end

    #-- mapping the room -------------------------------------------------------

    def assign_codes
        users = User.not_staff
        unique_codes = (1111..9999).to_a.sample(users.size)

        users.each_with_index do |user, index|
            user.update(pin: unique_codes[index], last_known_ip: nil)
        end
        render json: true
    end

    def list_codes
        @users = User.includes(:group, :schedule).not_admin # .order(:name)
        @schedules = @users.order("users.name").group_by { |u| u.schedule_name }
        @groups = User.includes(:group, :schedule).not_admin.order("schedules.name, groups.name, users.name").group_by { |u| [ u.schedule_name, u.group_name ] }
        render layout: false
    end

    def start_exam_mode
        Settings.exam_current = params.expect :exam_id
        Settings.registration_phase = "exam"
        redirect_to admin_exams_path
    end

    def stop_exam_mode
        exam_id = Settings.exam_current

        # stop exam mode
        Settings.exam_current = nil
        Settings.registration_phase = "during"

        # lock this exam for all students (who took it) individually
        # so they can't just continue the same exam when we open it
        # for new students
        Exam.find(exam_id).lock_existing_students

        redirect_to admin_exams_path
    end

    def run_checks
        # run checks for all unchecked submissions for an exam
        # use the exam check config
        # refactor check running in pset(?)
    end

end
