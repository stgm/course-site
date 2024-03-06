class AddExamCodeToSubmits < ActiveRecord::Migration[7.0]
    def change
        add_column :submits, :exam_code, :string, null: true
    end
end
