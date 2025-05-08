class AssistanceController < ApplicationController

    include NavigationHelper

    before_action :authorize

    layout "app"

    def index
        @course_name = current_user.full_designation.gsub("\n", " &ndash; ")
        @assist_available = User.where("available > ?", DateTime.now)
    end

end
