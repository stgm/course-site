class AttendanceRecord < ApplicationRecord

	def self.create_for_user(user, is_local)
		# get current hour
		real_time = DateTime.now
		cutoff_time = DateTime.new(real_time.year, real_time.month, real_time.mday, real_time.hour)

		# save attendance record or update localness of request
		ar = AttendanceRecord.where(user_id: user.id, cutoff: cutoff_time).first_or_initialize
		ar.local = is_local
		ar.save

		# update user last_seen
		user.with_lock do 
			user.update_attributes(last_seen_at: DateTime.now)
		end
	end

end
