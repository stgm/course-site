class Note < ApplicationRecord
	
	belongs_to :student, class_name: "User"
	belongs_to :author, class_name: "User"
	delegate :name, to: :author, prefix: true, allow_nil: true
	
end
