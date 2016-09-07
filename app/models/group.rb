class Group < ActiveRecord::Base

	extend FriendlyId
	friendly_id :name, :use => :slugged

	has_many :users
	
	def self.import_user(user_id, group_name, user_name, user_mail)
		if login = Login.where(login: user_id).first
			if user = login.user
				user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
				if !group_name.blank? and group_name != "No group"
					group = Group.where(:name => group_name).first_or_create
					user.group = group
					user.save
				else
					user.group = nil
					user.save
				end
			end
		end
	end
	
	def self.import(source)
		User.update_all(group_id: nil)
		Group.delete_all
	
		source.each_line do |line|
			next if line.strip == ""
			line = line.split("\t")

			user_id = line[0..1]
			group_name = line[8] && line[8].strip
			user_name = line[3] + " " + line[2].split(",").reverse.join(" ")
			user_mail = line[4] && line[4].strip
			next if !group_name || group_name == "Group"

			if user_id[0] == user_id[1]
				self.import_user(user_id[0], group_name, user_name, user_mail)
			else
				self.import_user(user_id[0], group_name, user_name, user_mail)
				self.import_user(user_id[1], group_name, user_name, user_mail)
			end
		end
	end

end


			#
			# if user_id[0] == user_id[1]
			# 	login = Login.where(login: user_id[0]).first_or_create
			# 	user = login.user or (user = login.create_user and login.save)
			# 	user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
			# 	if group_name != ""
			# 		group = Group.where(:name => group_name).first_or_create
			# 		user.group = group
			# 		user.save
			# 	else
			# 		user.group = nil
			# 		user.save
			# 	end
			# else
			# 	first_user = User.with_login(user_id[0]).first
			# 	second_user = User.with_login(user_id[1]).first
			# 	if first_user.nil? && second_user.nil?
			# 		login = Login.where(login: user_id[0]).first_or_create
			# 		user = login.user or (user = login.create_user and login.save)
			# 		login2 = Login.where(login: user_id[1]).first_or_create
			# 		login2.user = login.user and login2.save
			# 		user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
			# 		if group_name != ""
			# 			group = Group.where(:name => group_name).first_or_create
			# 			user.group = group
			# 			user.save
			# 		else
			# 			user.group = nil
			# 			user.save
			# 		end
			# 	elsif first_user == second_user
			# 		user = first_user
			# 		if group_name != ""
			# 			group = Group.where(:name => group_name).first_or_create
			# 			user.group = group
			# 			user.save
			# 		else
			# 			user.group = nil
			# 			user.save
			# 		end
			# 	elsif first_user.nil?
			# 		login = Login.where(login: user_id[0]).first_or_create
			# 		login.user = second_user and login.save
			# 		user = second_user
			# 		if group_name != ""
			# 			group = Group.where(:name => group_name).first_or_create
			# 			user.group = group
			# 			user.save
			# 		else
			# 			user.group = nil
			# 			user.save
			# 		end
			# 	elsif second_user.nil?
			# 		login = Login.where(login: user_id[1]).first_or_create
			# 		login.user = first_user and login.save
			# 		user = first_user
			# 		if group_name != ""
			# 			group = Group.where(:name => group_name).first_or_create
			# 			user.group = group
			# 			user.save
			# 		else
			# 			user.group = nil
			# 			user.save
			# 		end
			# 	end
			# end
