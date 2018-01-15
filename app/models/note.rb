class Note < ActiveRecord::Base
	
	belongs_to :author, class_name: "User"
	belongs_to :student, class_name: "User"
	
end
