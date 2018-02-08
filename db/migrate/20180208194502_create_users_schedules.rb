class CreateUsersSchedules < ActiveRecord::Migration
	def change
		create_table :schedules_users, id: false do |t|
			t.belongs_to :user, index: true
			t.belongs_to :schedule, index: true
		end
	end
end
