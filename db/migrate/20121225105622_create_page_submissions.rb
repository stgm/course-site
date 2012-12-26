class CreatePageSubmissions < ActiveRecord::Migration
	def change
		create_table :page_submissions do |t|
			t.references :page
			t.string :filename
			t.boolean :required

			t.timestamps
		end
		add_index :page_submissions, :page_id
	end
end
