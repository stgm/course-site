class AddSelfServiceToSchedule < ActiveRecord::Migration
	def change
		add_column :schedules, :self_service, :boolean, default: false, null: false
	end
end
