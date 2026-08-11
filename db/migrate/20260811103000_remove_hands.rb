class RemoveHands < ActiveRecord::Migration[8.0]

    # The question queue moved to the separate hands app, taking location
    # tracking with it. Attendance stays, including confirmation -- staff now
    # check students in by name instead of by table. See
    # doc/hands-location-and-statistics.md for what the dropped columns held.
    def up
        drop_table :hands

        remove_column :users, :hands_count
        remove_column :users, :hands_duration_count
        remove_column :users, :available
        remove_column :users, :last_known_location
        rename_column :users, :location_confirmed, :attendance_confirmed

        remove_column :attendance_records, :location
    end

    def down
        raise ActiveRecord::IrreversibleMigration
    end

end
