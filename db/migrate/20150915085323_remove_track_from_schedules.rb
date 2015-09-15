class RemoveTrackFromSchedules < ActiveRecord::Migration
	def change
		remove_reference :schedules, :track, index: true, foreign_key: true
	end
end
