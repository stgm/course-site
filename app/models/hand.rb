class Hand < ActiveRecord::Base

	belongs_to :user
	belongs_to :assist, class_name: "User"

end
