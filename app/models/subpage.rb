class Subpage < ActiveRecord::Base

	extend FriendlyId
	friendly_id :title, :use => :slugged

	attr_accessible :content, :page, :position, :title

	belongs_to :page

end
