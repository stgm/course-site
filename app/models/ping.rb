class Ping < ApplicationRecord

	belongs_to :user
	
	scope :active, -> { where(active:true) }
	scope :assistants, -> { includes(:user).where("users.uvanetid in (?)", (Settings['admins'] or []) + (Settings['assistants'] or [])) }
	scope :students, -> { includes(:user).where("users.uvanetid not in (?)", (Settings['admins'] or []) + (Settings['assistants'] or [])) }

end
