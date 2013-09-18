class User < ActiveRecord::Base
	
	attr_accessible :avatar, :mail, :name, :uvanetid
	belongs_to :group
	has_many :submits

	def submit(pset)
		submits.where(:pset_id => pset.id).first
	end
	
	def activate
		update_attribute :active, true
	end

end
