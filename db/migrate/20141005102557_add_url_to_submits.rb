class AddUrlToSubmits < ActiveRecord::Migration
	def change
		add_column :submits, :url, :string
	end
end
