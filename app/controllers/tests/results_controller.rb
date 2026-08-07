class Tests::ResultsController < Tests::TestsController

    include NavigationHelper

    before_action :authorize
    before_action :require_senior

    layout "modal"

    def index
        @psets = Pset.where(name: current_schedule.grading_config.tests).order(:order)
    end

    def show
        @pset = Pset.find_by_id(params[:test_id])
        @pset_config = Submit.find_or_initialize_by(user: current_user, pset: @pset).grading_config
        @psets = Pset.all

        @students = current_user.accessible_students.student.order("lower(name)")
        render plain: "No students" and return if @students.none?

        @config = @pset.grading_config(current_schedule)
        @subgrade_names = (@config&.dig("subgrades") || {}).keys
        @aggregate_function = GradingFormulaEvaluator.aggregate_function(@config&.dig("calculation"))

        # one query for the whole list rather than one per student; user and
        # schedule come along because the grade's config is resolved through them
        @submits = Submit.where(pset_id: @pset.id, user_id: @students.ids).
            includes(:grade, :pset, user: :schedule).index_by(&:user_id)
    end

    def update
        pset_id = params[:test_id]
        allowed_ids = current_user.accessible_students.ids.to_set

        params[:grades].each do |user_id, info|
            next unless allowed_ids.include?(user_id.to_i)
            subgrades = submitted_subgrades(info[:subgrades])
            # check if any of the subgrades has been filled
            next unless subgrades.values.any?(&:present?)

            s = Submit.where(user_id: user_id, pset_id: pset_id).first_or_create
            g = s.grade || s.build_grade(grader: current_user)
            apply_subgrades(g, subgrades)
            g.notes = info[:notes]
            # published to the student, unlike notes
            g.comments = info[:comments]
            # if anything's new, reset grade published-ness and save
            if g.changed?
                g.grader = current_user
                g.status = Grade.statuses[:finished]
                g.save
            end
        end

        # not :notice, which the layout would put in a banner above the grid and
        # push every row down; the footer shows this one beside the save button
        redirect_to test_results_path(test_id: pset_id), flash: { saved: "Saved" }
    end

    # What one row of the grid would come out as if it were saved right now.
    def calculate
        pset = Pset.find_by_id(params[:test_id])
        user_id = params[:user_id].to_i
        return head :not_found if pset.blank? || pset.grading_config(current_schedule).blank?
        return head :forbidden unless current_user.accessible_students.ids.include?(user_id)

        # an unsaved Grade answers this by itself, using the same coercion,
        # formula and rounding a save would go through
        submit = Submit.find_or_initialize_by(user_id: user_id, pset_id: pset.id)
        grade = submit.grade || submit.build_grade
        apply_subgrades(grade, submitted_subgrades(params[:subgrades]))
        grade.set_calculated_grade

        render json: {
            grade: grade.calculated_grade,
            display: Grade::Formatter.format_value(grade.calculated_grade, grade.type),
            aggregate: grade.aggregate_value
        }
    end

    private

    # Subgrade names come from the grading config, so they cannot be listed
    # ahead of time and the hash is taken as it arrives.
    def submitted_subgrades(source)
        source.blank? ? {} : source.permit!.to_h
    end

    # Shared by update and calculate so that the preview and the save can never
    # disagree. Blank entries are left alone rather than clearing the stored
    # value; assignment goes through Grade::SubGrades for typed coercion.
    def apply_subgrades(grade, subgrades)
        filled = subgrades.select { |_, value| value.present? }
        grade.subgrades = grade.subgrades.to_h.merge(filled)
    end

end
