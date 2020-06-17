class Page < ApplicationRecord

	belongs_to :section, optional: true
	
	has_many :subpages, dependent: :destroy
	has_one  :pset  # should never be destroyed, because may have submits

	# this generates a url friendly part for the page
	extend FriendlyId
	friendly_id :title, use: [ :slugged, :scoped ], scope: :section

	# Make sure the subpages are always ordered
	default_scope { order(:position, :title) }
	
	def public_url
		the_path = ["/course"]
		the_path << Course.submodule if Course.submodule
		the_path << section.path if section
		the_path << path
		
		return File.join(the_path)
	end
	
end
