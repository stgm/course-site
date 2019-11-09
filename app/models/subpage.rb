class Subpage < ApplicationRecord

	# this generates a url friendly part for the subpage (used for html ids in this case)
	extend FriendlyId
	friendly_id :title, :use => :slugged

	belongs_to :page

	default_scope { order(:position) }

end
