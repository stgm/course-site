class TutorialsController < ApplicationController

    before_action :authorize
    before_action :require_active_user
    before_action :require_senior, only: [ :create, :update, :show, :recheck, :participation ]
    before_action :load_own_tutorial, only: [ :update, :show, :recheck, :participation ]
    before_action :redirect_in_exam_mode

    layout "sidebar"

    # Staff see their own tutorials and the practice exams to start one from.
    # Students see the tutorials they claimed and a field to enter a PIN.
    def index
        @body_class = "exam_list"
        if current_user.senior?
            @tutorials = Tutorial.includes(:exam, :memberships).where(owner: current_user).order(created_at: :desc)
            @exams = Exam.practice.includes(:pset).order("psets.name")
        else
            @tutorials = current_user.tutorials.includes(:exam).order(created_at: :desc)
            @exams = Exam.practice.joins(:pset).where(locked: false).order("psets.name")
        end
    end

    def create
        tutorial = Tutorial.new(exam: Exam.practice.find(params.expect(:exam_id)), owner: current_user,
                                schedule_id: current_user.schedule_id)
        if tutorial.save
            redirect_to tutorials_path
        else
            redirect_to tutorials_path, alert: tutorial.errors.full_messages.to_sentence
        end
    end

    # Opens or closes a tutorial. Closing only stops new claims.
    def update
        @tutorial.update!(params.expect(tutorial: [ :open ]))
        head :ok
    end

    # Lists the participants of one tutorial, with their checks and attendance.
    def show
        @body_class = "exam_list"
        @pset = @tutorial.exam.pset
        @participants = @tutorial.users.includes(:schedule).order(:name)
        @submits = Submit.where(pset: @pset, user: @participants).includes(:grade).index_by(&:user_id)
        @checkable = @pset.submit_config["check"].present? && CheckSender.enabled?
    end

    # Runs the automatic checks for one participant, or for all of them.
    def recheck
        pset = @tutorial.exam.pset
        submits = Submit.where(pset: pset, user: @tutorial.users)
        submits = submits.where(user_id: params[:user_id]) if params[:user_id].present?
        submits.each { |submit| submit.recheck_later(api_check_result_do_url) }
        redirect_to tutorial_path(@tutorial), notice: t("tutorial.running_checks")
    end

    # Sets or clears the first boolean subgrade (attendance) for one participant.
    def participation
        user = @tutorial.users.find(params.expect(:user_id))
        name = @tutorial.attendance_subgrade(user)
        return head(:unprocessable_entity) if name.nil?

        submit = Submit.where(user: user, pset: @tutorial.exam.pset).first_or_create
        grade = submit.grade || submit.build_grade(grader: current_user)
        grade.subgrades = grade.subgrades.to_h.merge(name => params[:checked] == "1" ? -1 : 0)
        grade.grader = current_user
        grade.status = Grade.statuses[:finished]
        grade.save!
        head :ok
    end

    # A student enters the PIN of an open tutorial and keeps access from then on.
    def claim
        tutorial = Tutorial.find_by(pin: params[:pin].to_s.strip, open: true)
        if tutorial.nil?
            redirect_to tutorials_path, alert: t("tutorial.unknown_pin")
        elsif !tutorial.claimable_by?(current_user)
            redirect_to tutorials_path, alert: t("tutorial.wrong_schedule")
        else
            TutorialMembership.find_or_create_by!(tutorial: tutorial, user: current_user)
            redirect_to tutorials_path, notice: t("tutorial.claimed", name: tutorial.name.humanize)
        end
    end

    private

    # Only the owner of a tutorial, or an admin, may look at its participants.
    def load_own_tutorial
        @tutorial = Tutorial.includes(exam: :pset).find(params[:id])
        head :forbidden unless @tutorial.owner == current_user || current_user.admin?
    end

    # Exam mode only allows the current exam, so there is nothing to do here.
    def redirect_in_exam_mode
        redirect_to exams_path if Settings.registration_phase == "exam"
    end

end
