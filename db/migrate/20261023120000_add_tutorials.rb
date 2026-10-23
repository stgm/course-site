class AddTutorials < ActiveRecord::Migration[8.0]
    def change
        # "exam" is a real exam, "practice" is only offered through tutorials
        add_column :exams, :kind, :string, null: false, default: "exam"

        create_table :tutorials do |t|
            t.references :exam, null: false, foreign_key: true
            t.references :user, null: false, foreign_key: true
            t.string :pin, null: false
            t.boolean :open, null: false, default: false
            t.timestamps
        end
        add_index :tutorials, :pin, unique: true

        create_table :tutorial_memberships do |t|
            t.references :tutorial, null: false, foreign_key: true
            t.references :user, null: false, foreign_key: true
            t.timestamps
        end
        add_index :tutorial_memberships, [ :tutorial_id, :user_id ], unique: true
    end
end
