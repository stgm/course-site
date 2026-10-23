class TutorialsController < ApplicationController

    before_action :authorize
    before_action :require_active_user
    before_action :require_senior, only: [ :create, :update ]
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
        tutorial = Tutorial.new(exam: Exam.practice.find(params.expect(:exam_id)), owner: current_user)
        if tutorial.save
            redirect_to tutorials_path
        else
            redirect_to tutorials_path, alert: tutorial.errors.full_messages.to_sentence
        end
    end

    # Opens or closes a tutorial. Closing only stops new claims.
    def update
        tutorial = Tutorial.find(params[:id])
        return head(:forbidden) unless tutorial.owner == current_user || current_user.admin?

        tutorial.update!(params.expect(tutorial: [ :open ]))
        head :ok
    end

    # A student enters the PIN of an open tutorial and keeps access from then on.
    def claim
        tutorial = Tutorial.find_by(pin: params[:pin].to_s.strip, open: true)
        if tutorial.nil?
            redirect_to tutorials_path, alert: t("tutorial.unknown_pin")
        else
            TutorialMembership.find_or_create_by!(tutorial: tutorial, user: current_user)
            redirect_to tutorials_path, notice: t("tutorial.claimed", name: tutorial.name.humanize)
        end
    end

    private

    # Exam mode only allows the current exam, so there is nothing to do here.
    def redirect_in_exam_mode
        redirect_to exams_path if Settings.registration_phase == "exam"
    end

end
