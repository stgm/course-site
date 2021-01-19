class Note < ApplicationRecord
	
	belongs_to :student, class_name: "User"
	belongs_to :author, class_name: "User"
	belongs_to :assignee, class_name: "User", optional: true
	delegate :name, to: :author, prefix: true, allow_nil: true
	
	def sortable_date
		updated_at
	end
	
end
