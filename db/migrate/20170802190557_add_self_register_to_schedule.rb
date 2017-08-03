class AddSelfRegisterToSchedule < ActiveRecord::Migration
	def change
		add_column :schedules, :self_register, :boolean, default: false, null: false
	end
end
