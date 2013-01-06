class CreatePsetFiles < ActiveRecord::Migration
  def change
    create_table :pset_files do |t|
      t.string :filename
      t.boolean :required
      t.references :pset

      t.timestamps
    end
    add_index :pset_files, :pset_id
  end
end
