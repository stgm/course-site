class Hand < ActiveRecord::Base

	belongs_to :user
	belongs_to :assist, class_name: "User"
	
	after_save do |hand|
		if hand.done
			hand.user.update_attribute(:last_spoken_at, DateTime.now)
		end
	end

	def user_last_seen
		if attend = self.user.attendance_records.order('cutoff desc').first
			attend.cutoff
		else
			nil
		end
	end

end
