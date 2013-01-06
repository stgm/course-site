class DropPageSubmissions < ActiveRecord::Migration
	def up
		drop_table :page_submissions
	end

	def down
		create_table "page_submissions", :force => true do |t|
			t.integer  "page_id"
			t.string   "filename"
			t.boolean  "required"
			t.datetime "created_at", :null => false
			t.datetime "updated_at", :null => false
		end

		add_index "page_submissions", ["page_id"], :name => "index_page_submissions_on_page_id"
	end
end
