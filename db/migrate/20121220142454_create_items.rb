class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :title
      t.integer :position
      t.string :reference
      t.references :category

      t.timestamps
    end
  end
end
