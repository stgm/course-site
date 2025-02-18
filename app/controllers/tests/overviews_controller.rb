class Tests::OverviewsController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_senior

    def show
        @psets = Pset.where(name: current_schedule.grading_config.tests["submits"].keys)
        @students = User.includes(submits: :grade).where(submits: { pset_id: @psets }).where("grades.calculated_grade = 0").order(:name)
        render layout: false
    end

end
