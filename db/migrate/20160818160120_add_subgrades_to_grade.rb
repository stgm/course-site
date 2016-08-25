class AddSubgradesToGrade < ActiveRecord::Migration
	def up
		add_column :grades, :subgrades, :text
		Grade.all.each do |g|
			g.subgrades = OpenStruct.new('scope' => g.scope, 'correctness' => g.correctness, 'design' => g.design, 'style' => g.style)
			g.save
		end
	end
	
	def down
		remove_column :grades, :subgrades
	end
end
