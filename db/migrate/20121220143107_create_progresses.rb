class CreateProgresses < ActiveRecord::Migration
  def change
    create_table :progresses do |t|
      t.references :user
      t.references :page
      t.boolean :done

      t.timestamps
    end
  end
end
