class User < ActiveRecord::Base
	
	attr_accessible :avatar, :mail, :name, :uvanetid

	belongs_to :group

	has_many :submits
	has_many :psets, through: :submits
	# has_many :registrations

	def submit(pset)
		submits.where(:pset_id => pset.id).first
	end
	
	def activate
		update_attribute :active, true
	end
	
	scope :admin,     -> { where("uvanetid in (?)", (Settings['admins'] or []) + (Settings['assistants'] or [])) }
	scope :not_admin, -> { where("uvanetid not in (?)", (Settings['admins'] or []) + (Settings['assistants'] or [])) }
	scope :active,    -> { where(active: true) }
	scope :no_group,  -> { where(group_id: nil) }
	scope :but_not,   -> users { where("users.id not in (?)", users) }
	
	scope :from_term, -> term  { where("term" => term) if not (term.nil? or term.empty?) }
	scope :having_status, -> status  { where("status" => status) if not (status.nil? or status.empty?) }
	
	belongs_to :schedule
	belongs_to :schedule_span

	attr_accessible :term, :status, :schedule_id, :schedule_span_id
	
	# ensure that if a schedule is selected, a valid schedule_span is also present
	before_save do |r|
		if r.schedule.present?
			logger.debug "SCHED PRES"
			if r.schedule_span.present?
				logger.debug "SPAN PRES"
				r.schedule_span = r.schedule.schedule_spans.first if not r.schedule.schedule_spans.include?(r.schedule_span)
			else
				logger.debug "SPAN NOT PRES"
				r.schedule_span = r.schedule.schedule_spans.first
			end
		else
			logger.debug "nuttin PRES"
			
			r.schedule_span = nil
		end
	end

	def valid_profile?
		return !self.name.blank?
	end
	
	def can_submit?
		if Group.any?
			can = self.valid_profile? && self.group.present?
		else
			can = self.valid_profile?
		end		
		return can
	end
	
	def is_admin?
		admins = Settings['admins']
		return admins && admins.include?(self.uvanetid)
	end
	
	def is_assistant?
		assistants = Settings['assistants']
		return assistants && assistants.include?(self.uvanetid)
	end
	
	def generate_token!
		self.token = SecureRandom.hex(16)
		self.save
	end
	
end
