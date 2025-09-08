module AttendanceRecorder

    extend ActiveSupport::Concern

    included do
        before_action :register_attendance
    end

    def register_attendance
        if logged_in? && (!session[:last_seen_at] ||
                           session[:last_seen_at] < 2.minutes.ago)
            session[:last_seen_at] = Time.now
            current_user.log_attendance ip: request.remote_ip
        end
    end

end
