class Page < ActiveRecord::Base

	extend FriendlyId
	friendly_id :title, use: :slugged

	attr_accessible :content, :position, :section, :title

	belongs_to :section
	has_many :subpages

end
