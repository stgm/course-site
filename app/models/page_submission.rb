class PageSubmission < ActiveRecord::Base
	belongs_to :page
	attr_accessible :filename, :required
end
