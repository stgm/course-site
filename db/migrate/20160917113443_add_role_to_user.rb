class AddRoleToUser < ActiveRecord::Migration
	def change
		add_column :users, :role, :integer, null: false, default: 0
		User.all.each do |u|
			admins = Settings['admins']
			assistants = Settings['assistants']
			if admins && (admins & u.logins.pluck(:login)).size > 0
				u.admin!
			elsif assistants && (assistants & u.logins.pluck(:login)).size > 0
				u.assistant!
			else
				u.student!
			end
		end
	end
end
