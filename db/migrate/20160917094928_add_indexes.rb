class AddIndexes < ActiveRecord::Migration
  def change
	  add_index :hands, :user_id
	  add_index :hands, :assist_id	  
  end
end
