class CreateGrades < ActiveRecord::Migration
	def change
		create_table :grades do |t|
			t.references :submit
			t.string :grader
			t.integer :scope
			t.integer :correctness
			t.integer :design
			t.integer :style
			t.text :comments
			t.integer :grade

			t.timestamps
		end
		add_index :grades, :submit_id
	end
end
