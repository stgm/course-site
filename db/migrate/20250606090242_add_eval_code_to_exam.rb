class AddEvalCodeToExam < ActiveRecord::Migration[8.0]
    def change
        add_column :exams, :eval_code, :string
    end
end
