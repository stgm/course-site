class Page < ApplicationRecord

	# this generates a url friendly part for the page
	extend FriendlyId
	friendly_id :title, use: [ :slugged, :scoped ], scope: :section

	belongs_to :section, optional: true  # parent section
	has_many :subpages                   # content tabs
	has_one :pset                        # linked pset if available

	# Make sure the subpages are always ordered
	default_scope { order(:position) }
	
	def public_url
		the_path = ["/course"]
		the_path << Settings.submodule if Settings.submodule
		the_path << section.path if section
		the_path << path
		
		return File.join(the_path)
	end
	
end
