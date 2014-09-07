class AddScheduleToUser < ActiveRecord::Migration
	def change
		add_column :users, :term, :string
		add_column :users, :status, :string
		add_reference :users, :schedule, index: true
		add_reference :users, :schedule_span, index: true
		
		User.all.each do |u|
			if r = u.registrations.first
				u.term = r.term
				u.status = r.status
				u.schedule_id = r.schedule_id
				u.schedule_span_id = r.schedule_span_id
				u.save
			end
		end
	end
end
