class CreateQuestions < ActiveRecord::Migration[7.0]
    def change
        create_table :questions do |t|
            t.references :user, null: false, foreign_key: true
            t.references :page, null: false, foreign_key: true
            t.boolean :locked, default: false
            t.boolean :hidden, default: false

            t.timestamps
        end
    end
end
