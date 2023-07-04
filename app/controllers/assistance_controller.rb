class AssistanceController < ApplicationController

    include NavigationHelper

    before_action :authorize

    def index
        @course_name = Schedule.count > 1 && current_schedule.name || Course.long_name
        @assist_available = User.where('available > ?', DateTime.now)
    end

end
