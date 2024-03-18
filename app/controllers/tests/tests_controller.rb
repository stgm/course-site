class Tests::TestsController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_senior

    layout 'modal'

    def index
        @psets = Pset.where(name: current_schedule.grading_config.tests).order(:order)
    end

end
