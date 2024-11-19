class AddCurrentExamToExams < ActiveRecord::Migration[7.0]
    def change
        add_column :exams, :current_exam, :boolean, default: false
    end
end
