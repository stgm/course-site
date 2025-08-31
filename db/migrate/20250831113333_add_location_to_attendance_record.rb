class AddLocationToAttendanceRecord < ActiveRecord::Migration[8.0]
    def change
        add_column :attendance_records, :location, :string
        add_column :attendance_records, :ip, :string
        add_column :attendance_records, :confirmed, :boolean, default: false, null: false
    end
end
