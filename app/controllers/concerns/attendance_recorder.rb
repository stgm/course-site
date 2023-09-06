module AttendanceRecorder
    extend ActiveSupport::Concern

    included do
        before_action :delete_last_known_location
        before_action :register_attendance
    end

    def delete_last_known_location
        if !session[:last_seen_at] || session[:last_seen_at] < 12.hours.ago
            current_user.update(last_known_location: nil)
        end
    end

    def register_attendance
        if ( !session[:last_seen_at] || session[:last_seen_at] &&
              session[:last_seen_at] < 15.minutes.ago ) &&
              logged_in?
            session[:last_seen_at] = Time.now
            AttendanceRecord.create_for_user(current_user, request_from_local_network?)
        end
    end
end
