class Group < ApplicationRecord
	
	#
	# Group is about grading: it defines a set of students that one grader might grade
	#

	extend FriendlyId
	friendly_id :name, use: :slugged
	
	belongs_to :schedule
	
	# these are the students
	has_many :users
	has_many :students, class_name: "User"
	
	# these are the staff that has been assigned to grade this group
	has_and_belongs_to_many :graders, class_name: "User"
	def grader_names
		graders.map{|g|g.name.split.first}.join ", "
	end

	has_many :submits, -> { where(users: {status: 'active'}) } , through: :users
	has_many :grades, -> { where(users: {status: 'active'}) }, through: :submits

end
