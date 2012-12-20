class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :title
      t.integer :position
      t.references :subpage

      t.timestamps
    end
  end
end
