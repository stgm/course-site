class CreatePsets < ActiveRecord::Migration
  def change
    create_table :psets do |t|
      t.string :name
      t.text :description
      t.references :page

      t.timestamps
    end
    add_index :psets, :page_id
  end
end
