class Group < ApplicationRecord
	
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

	has_many :submits, -> { where(users: {active: true}) } , through: :users
	has_many :grades, -> { where(users: {active: true}) }, through: :submits
	
	# def self.import_user(user_id, group_name, user_name, user_mail)
	# 	if login = Login.where(login: user_id).first
	# 		if user = login.user
	# 			user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
	# 			if !group_name.blank? and group_name != "No group"
	# 				group = Group.where(:name => group_name).first_or_create
	# 				user.group = group
	# 				user.save
	# 			else
	# 				user.group = nil
	# 				user.save
	# 			end
	# 		end
	# 	end
	# end
	

end
