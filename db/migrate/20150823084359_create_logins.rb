class CreateLogins < ActiveRecord::Migration
	def change

		create_table :logins do |t|
			t.string :login
			t.references :user, index: true, foreign_key: true
		end
		
		reversible do |dir|			
			dir.up do
				User.all.each do |u|
					Login.create do |l|
						l.login = u.uvanetid
						l.user = u
					end
				end
			end
			
			dir.down do
			end
		end
	end
end
