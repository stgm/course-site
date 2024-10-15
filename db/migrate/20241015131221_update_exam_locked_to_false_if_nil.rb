class UpdateExamLockedToFalseIfNil < ActiveRecord::Migration[7.0]
    def up
        # Update existing nil values to true
        Exam.where(locked: nil).update_all(locked: true)

        # Change the default value of the column
        change_column_default :exams, :locked, from: nil, to: true
    end

    def down
        # Revert is not needed
    end
end
