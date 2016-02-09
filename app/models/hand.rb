class Hand < ActiveRecord::Base

	belongs_to :user
	belongs_to :assist, class_name: "User"

	def user_last_seen
		if attend = self.user.attendance_records.order('cutoff desc').first
			attend.cutoff
		else
			nil
		end
	end

end
