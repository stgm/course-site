class CreateHands < ActiveRecord::Migration
	def change
		create_table :hands do |t|
			t.references :user
			t.string :location
			t.text :help_question
			t.boolean :done, default: false
			t.integer :assist_id
	        t.timestamps
		end
	end
end
