class AddCurrentToSchedule < ActiveRecord::Migration
	def change
		add_reference :schedules, :current_schedule_span
	end
end
