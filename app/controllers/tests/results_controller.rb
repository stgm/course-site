class Tests::ResultsController < Tests::TestsController

    include NavigationHelper

    before_action :authorize
    before_action :require_senior

    layout 'modal'

    def index
        @psets = Pset.where(name: current_schedule.grading_config.tests).order(:order)
    end

    def show
        @pset = Pset.find_by_id(params[:test_id])
        @pset_config = Submit.find_or_initialize_by(user: current_user, pset: @pset).grading_config
        @psets = Pset.all

        if current_user.groups.any?
            @groups = current_user.groups
        elsif current_user.schedule.present?
            @groups = current_user.schedule.groups
        else
            render plain: "No students"
        end

        @students = User.student.where(group: @groups).order('lower(name)')
    end

    def update
        # render text: params.inspect and return
        grades = params[:grades]
        pset_id = params[:test_id]

        grades.each do |user_id, info|
            notes = info[:notes]
            subgrades = info[:subgrades]
            # check if any of the subgrades has been filled
            if subgrades.values.map(&:present?).any?
                s = Submit.where(user_id: user_id, pset_id: pset_id).first_or_create
                if g = s.grade
                    subgrades.each do |name, value|
                        if value.present?
                            if value.to_i.to_s == value
                                g.subgrades[name] = value.to_i
                            else
                                g.subgrades[name] = value.to_f
                            end
                        end
                    end
                    g.notes = notes
                    # if anything's new, reset grade published-ness and save
                    if g.changed?
                        g.grader = current_user
                        g.status = Grade.statuses[:finished]
                        g.save
                    end
                else
                    g = s.build_grade(grader: current_user)
                    subgrades.each do |name, value|
                        if value.present?
                            if value.to_i.to_s == value
                                g.subgrades[name] = value.to_i
                            else
                                g.subgrades[name] = value.to_f
                            end
                        end
                    end
                    g.notes = notes
                    g.status = Grade.statuses[:finished]
                    g.save
                end
            end
        end

        redirect_to test_results_path(test_id: pset_id), notice: "Saved."
    end

end
