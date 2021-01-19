class Hand < ApplicationRecord

	belongs_to :user, touch: true

	belongs_to :assist, class_name: "User", optional: true
	delegate :name, to: :assist, prefix: true, allow_nil: true
	
	scope :waiting, -> { where(assist_id: nil).where.not(done: true) }
	scope :successfully_helped, -> { where(success: true) }
	scope :total_helping_time, -> { sum('(JulianDay(closed_at) - JulianDay(claimed_at)) * 60 * 24').round }
	
	after_validation do |hand|
		if hand.done
			hand.user.update_attribute(:last_spoken_at, DateTime.now)
		end
		if hand.success
			AttendanceRecord.create_for_user(hand.user, true)
		end
	end

	def user_last_seen
		if attend = self.user.attendance_records.order('cutoff desc').first
			attend.cutoff
		else
			nil
		end
	end

	def sortable_date
		updated_at
	end
	
end
