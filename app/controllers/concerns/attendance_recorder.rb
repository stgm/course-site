module AttendanceRecorder
    extend ActiveSupport::Concern

    included do
        before_action :register_attendance
    end

    def register_attendance
        if ( !session[:last_seen_at] || session[:last_seen_at] &&
              session[:last_seen_at] < 15.minutes.ago ) &&
              logged_in?
            AttendanceRecord.create_for_user(current_user, request_from_local_network?)
            session[:last_seen_at] = Time.now
        end
    end
end
