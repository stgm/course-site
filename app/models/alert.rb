class Alert < ActiveRecord::Base
	attr_accessible :title, :body, :published
end
