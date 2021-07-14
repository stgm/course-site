class RemoveAssigneeFromNotes < ActiveRecord::Migration[6.1]
    def change
        remove_reference :notes, :assignee
    end
end
