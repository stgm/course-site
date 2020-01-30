class Group < ApplicationRecord
	
	#
	# Group is about grading: it defines a set of students that one grader might grade
	#

	extend FriendlyId
	friendly_id :name, use: :slugged
	
	belongs_to :schedule
	
	# these are the students
	has_many :users
	
	# these are the staff that has been assigned to grade this group
	has_and_belongs_to_many :graders, class_name: "User"

	has_many :submits, -> { where(users: {active: true}) } , through: :users
	has_many :grades, -> { where(users: {active: true}) }, through: :submits

end
