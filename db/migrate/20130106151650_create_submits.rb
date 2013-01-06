class CreateSubmits < ActiveRecord::Migration
  def change
    create_table :submits do |t|
      t.references :user
      t.references :pset
      t.datetime :submitted_at

      t.timestamps
    end
    add_index :submits, :user_id
    add_index :submits, :pset_id
  end
end
