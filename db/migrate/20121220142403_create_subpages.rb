class CreateSubpages < ActiveRecord::Migration
  def change
    create_table :subpages do |t|
      t.string :title
      t.text :content
      t.integer :position
      t.references :page

      t.timestamps
    end
  end
end
