class AddUsedLoginToSubmit < ActiveRecord::Migration
	def change
		add_column :submits, :used_login, :string
		Submit.all.each do |s|
			if s.used_login.nil?
				s.update_attribute(:used_login, s.user.logins.first.login)
			end
		end
	end
end
