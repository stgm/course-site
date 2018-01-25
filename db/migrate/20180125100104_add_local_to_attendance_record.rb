class AddLocalToAttendanceRecord < ActiveRecord::Migration
  def change
    add_column :attendance_records, :local, :boolean
  end
end
