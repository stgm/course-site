class CreateAttendanceRecord < ActiveRecord::Migration
	def change
		create_table :attendance_records do |t|
			t.references :user, index: true, foreign_key: true
			t.datetime :cutoff
		end
	end
end
