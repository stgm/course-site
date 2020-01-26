class Note < ApplicationRecord
	
	belongs_to :student, class_name: "User", touch: true
	belongs_to :author, class_name: "User"
	delegate :name, to: :author, prefix: true, allow_nil: true
	
	def short_description
		"1 note written"
	end
	
end
