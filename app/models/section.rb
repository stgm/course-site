class Section < ActiveRecord::Base

	extend FriendlyId
	friendly_id :title, :use => :slugged

	attr_accessible :content, :position, :title, :path

	has_many :pages

end
