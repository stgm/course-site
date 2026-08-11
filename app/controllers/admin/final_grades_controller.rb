class Admin::FinalGradesController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_admin

    layout "modal"

    # every schedule's final grades, because a submission to the registration system
    # covers the whole course rather than one schedule
    def index
        @final_grade_names = GradingConfig.all_final_grade_names
        if @final_grade_names.any?
            redirect_to admin_final_grade_path(@final_grade_names.first)
        end
    end

    def show
        @final_grade_names = GradingConfig.all_final_grade_names
        @pending_counts = @final_grade_names.index_with { |name| pending_grades(name).count }

        @name = params[:name]
        @pending_grades = pending_grades(@name).
            includes(user: [ :schedule, :group ]).
            order("schedules.name", "groups.name")
        @exported_grades = exported_grades(@name).
            includes(user: [ :schedule, :group ]).
            order(exported_at: :desc)
    end

    # Downloads an xlsx of the selected grades for this type, and marks them
    # as submitted (with an admin-chosen timestamp) in the same request.
    def export
        @name = params[:final_grade_name]
        exported_at = params[:exported_at].present? ? Time.zone.parse(params[:exported_at]) : Time.current

        # scope to pending_grades(@name), not Grade.find, so a tampered grade_ids
        # param can't export/mark grades outside this type or already-exported ones
        @grades = pending_grades(@name).where(id: params[:grade_ids]).
            includes(user: [ :schedule, :group ]).
            order("schedules.name", "groups.name").to_a

        Grade.where(id: @grades.map(&:id)).
            update_all(status: Grade.statuses["exported"], exported_at: exported_at)

        respond_to do |format|
            format.xlsx
        end
    end

    # Reverts a single grade back to pending, in case it was exported by mistake.
    def undo_export
        # scoped to exported grades on a final pset, not Grade.find, so this can't be
        # used to tamper with grades outside the final-grades export workflow
        grade = Grade.joins(submit: :pset).where(psets: { final: true }).exported.find(params[:grade_id])
        grade.update!(status: :published, exported_at: nil)
        redirect_to admin_final_grade_path(grade.pset_name)
    end

    private

    # final: true keeps this to grades that are actually registered somewhere, so that a
    # name that is not a final grade cannot be exported and marked as such through the URL
    def psets(name)
        Pset.where(name: name, final: true)
    end

    def pending_grades(name)
        Grade.joins(submit: :pset).where(submits: { pset_id: psets(name) }).published
    end

    def exported_grades(name)
        Grade.joins(submit: :pset).where(submits: { pset_id: psets(name) }).exported
    end

end
