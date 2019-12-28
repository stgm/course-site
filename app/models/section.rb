class Section < ApplicationRecord

	has_many :pages

	# this generates a url friendly part for the section
	extend FriendlyId
	friendly_id :title, :use => :slugged

	serialize :content_links

	# Make sure the subpages are always ordered
	default_scope { order(:position) }
	
	def normalize_friendly_id(string)
		super.gsub("problem-sets", "psets")
	end

	def public_url
		the_path = ["/course"]
		the_path << Settings.submodule if Settings.submodule
		the_path << path
		
		return File.join(the_path)
	end

end
