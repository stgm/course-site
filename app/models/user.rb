class User < ActiveRecord::Base
	
	attr_accessible :avatar, :mail, :name, :uvanetid
	has_many :submits

	def submit(pset)
		submits.where(:pset_id => pset.id).first
	end

end
