class User < ActiveRecord::Base
	
	attr_accessible :avatar, :mail, :name, :uvanetid

	belongs_to :group

	has_many :submits
	has_many :psets, through: :submits
	has_many :registrations

	def submit(pset)
		submits.where(:pset_id => pset.id).first
	end
	
	def activate
		update_attribute :active, true
	end
	
	scope :admin,     -> { where("uvanetid in (?)", Settings['admins'] + (Settings['assistants'] or [])) }
	scope :not_admin, -> { where("uvanetid not in (?)", Settings['admins'] + (Settings['assistants'] or [])) }
	scope :inactive,  -> { where(active: false) }
	scope :active,    -> { where(active: true) }
	scope :but_not,   -> users { where("users.id not in (?)", users) }
	
	scope :from_term, -> term  { where("registrations.term" => term) if not (term.nil? or term.empty?) }
	scope :having_status, -> status  { where("registrations.status" => status) if not (status.nil? or status.empty?) }
	
end
