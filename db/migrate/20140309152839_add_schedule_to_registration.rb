class AddScheduleToRegistration < ActiveRecord::Migration
	def up
		add_column :registrations, :schedule_id, :integer
		add_column :registrations, :schedule_span_id, :integer
	end

	def down
		remove_column :registrations, :schedule_id
		remove_column :registrations, :schedule_span_id
	end
end
