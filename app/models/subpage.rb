class Subpage < ActiveRecord::Base
	belongs_to :page
	attr_accessible :content, :page, :position, :title
end
