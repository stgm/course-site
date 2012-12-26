class Page < ActiveRecord::Base

	extend FriendlyId
	friendly_id :title, use: :slugged

	attr_accessible :content, :position, :section, :title, :path, :form

	belongs_to :section
	has_many :subpages
	has_many :page_submissions
	
	def public_url()
		return File.join('/course', section.path, path)
	end
	
	def needs_submit?()
		return form || page_submissions.count > 0
	end

end
