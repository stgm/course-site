class User < ActiveRecord::Base
	attr_accessible :avatar, :mail, :name, :uvanetid
	has_many :submits
end
