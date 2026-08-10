class Admin::FinalGradesController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_admin

    layout "modal"

    def index
        @final_grade_names = GradingConfig.base.final_grade_names
        @pending_counts = @final_grade_names.index_with { |name| pending_grades(name).count }
    end

    def show
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

    private

    def psets(name)
        Pset.where(name: name)
    end

    def pending_grades(name)
        Grade.joins(submit: :pset).where(submits: { pset_id: psets(name) }).published
    end

    def exported_grades(name)
        Grade.joins(submit: :pset).where(submits: { pset_id: psets(name) }).exported
    end

end
