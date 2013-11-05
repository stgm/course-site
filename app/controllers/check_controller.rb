class CheckController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	#
	# List of homeworks to be check off by assistants
	#
	def index
		pset_id = params[:pset]
		@pset = Pset.where(name:pset_id).first
		existing_grades = Grade.joins(:submit => :user).where("submits.pset_id = ?", @pset.id).pluck("users.uvanetid")
		if(existing_grades.count > 0)
			@users = User.where('uvanetid not in (?)', existing_grades)
		else
			@users = User.all
		end
	end

end
