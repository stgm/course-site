class AttendanceRecord < ActiveRecord::Base

	def self.create_for_user(user)
		real_time = DateTime.now
		cutoff_time = DateTime.new(real_time.year, real_time.month, real_time.mday, real_time.hour)
		AttendanceRecord.where(user_id: user.id, cutoff: cutoff_time).first_or_create
		user.update_attributes(last_seen_at: DateTime.now)
	end

end
