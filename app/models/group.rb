class Group < ActiveRecord::Base
	
	#
	# Group is about grading: it defines a set of students that one grader might grade
	#

	extend FriendlyId
	friendly_id :name, :use => :slugged
	
	belongs_to :schedule
	
	# these are the students
	has_many :users
	
	# these are the staff that has been assigned to grade this group
	has_and_belongs_to_many :graders, class_name: "User"

	has_many :submits, through: :users
	has_many :grades, through: :submits
	
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
		# delete all groups that are not in use by assistants
		Group.where.not(id: Group.joins(:users).where("users.id": User.staff)).delete_all
	
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
