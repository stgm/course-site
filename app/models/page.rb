class Page < ActiveRecord::Base

	# this generates a url friendly part for the page
	extend FriendlyId
	friendly_id :title, use: [ :slugged, :scoped ], scope: :section

	attr_accessible :content, :position, :section, :title, :path, :form, :public

	belongs_to :section  # parent section
	has_many :subpages   # content tabs
	has_one :pset        # linked pset if available

	# Make sure the subpages are always ordered
	default_scope { order(:position) }
	
	def public_url
		if section
			return File.join('/course', section.path, path)
		else
			return File.join('/course', path)
		end
	end
	
end
