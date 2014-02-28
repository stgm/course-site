class Section < ActiveRecord::Base

	# this generates a url friendly part for the section
	extend FriendlyId
	friendly_id :title, :use => :slugged

	attr_accessible :content, :position, :title, :path

	has_many :pages

	# Make sure the subpages are always ordered
	default_scope { order(:position) }

end
