class AddFormContentsToSubmits < ActiveRecord::Migration[6.0]
	def change
		add_column :submits, :form_contents, :text
	end
end
