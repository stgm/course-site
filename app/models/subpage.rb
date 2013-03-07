class Subpage < ActiveRecord::Base

	# this generates a url friendly part for the subpage (used for html ids in this case)
	extend FriendlyId
	friendly_id :title, :use => :slugged

	attr_accessible :content, :page, :position, :title

	belongs_to :page

	default_scope order(:position)

end
