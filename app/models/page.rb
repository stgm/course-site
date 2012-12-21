class Page < ActiveRecord::Base
	belongs_to :section
	has_many :subpages
	attr_accessible :content, :position, :section, :title
end
