class AddScheduleToGroup < ActiveRecord::Migration
	def change
		add_reference :groups, :schedule, index: true, foreign_key: true
	end
end
