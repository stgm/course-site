class CreateExam < ActiveRecord::Migration[7.0]
    def change
        create_table :exams do |t|
            t.references :pset, null: false, foreign_key: true
            t.boolean :locked
            t.text :config

            t.timestamps
        end
    end
end
