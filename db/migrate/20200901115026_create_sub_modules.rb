class CreateSubModules < ActiveRecord::Migration[6.0]
	def change
		create_table :sub_modules do |t|
			t.string :name
			t.text :content_links
		end
	end
end
