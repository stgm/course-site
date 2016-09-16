class ChangeGrades < ActiveRecord::Migration
	def change
		change_table :grades do |t|
			t.rename :grader, :assist
			t.integer :grader_id
		end
		Grade.all.each do |g|
			if u = User.find_by_login(g.assist)
				g.update_attribute(:grader_id, u.id)
			end
		end
	end
end
