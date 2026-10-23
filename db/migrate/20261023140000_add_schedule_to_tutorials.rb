class AddScheduleToTutorials < ActiveRecord::Migration[8.0]
    def change
        # the schedule a student must be in to claim the code; null means anyone
        add_reference :tutorials, :schedule, foreign_key: true, null: true
    end
end
