class Schedules::AttendanceListsController < Schedules::ApplicationController

    before_action :authorize
    before_action :require_senior
    before_action :load_schedule
    before_action :verify_access

    # PDF of the students in a schedule, to sign off at an exam.
    def show
        send_data AttendanceList.new(@schedule).render,
            type: "application/pdf",
            disposition: "inline",
            filename: "#{@schedule.name.parameterize}-attendance-list.pdf"
    end

end
