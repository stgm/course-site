class Section < ActiveRecord::Base
	has_many :pages
	attr_accessible :content, :position, :title
end
