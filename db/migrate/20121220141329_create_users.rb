class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :uvanetid
      t.string :mail
      t.string :avatar

      t.timestamps
    end
  end
end
