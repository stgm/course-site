class AddScheduleToUser < ActiveRecord::Migration
	def change
		add_column :users, :term, :string
		add_column :users, :status, :string
		add_reference :users, :schedule, index: true
		add_reference :users, :schedule_span, index: true
	end
end
