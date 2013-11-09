class GradingController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	# 
	# List of problems to be graded by assistants
	#
	def index
		@submits = Submit.includes(:user, :pset, :grade).where("users.active = ? and users.done = ? and (grades.updated_at < submits.updated_at or grades.updated_at is null or grades.updated_at > ?)", true, false, 1.days.ago).order('psets.name')
	end

end
