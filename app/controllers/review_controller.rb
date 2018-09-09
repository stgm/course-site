class ReviewController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_senior
	
	layout "full-width"

	def index
		@users = current_user.schedule.users.includes(submits: [:grade, :pset]).where("grades.status in (?)", [Grade.statuses[:open], Grade.statuses[:finished]]).references(:grades).order("grades.grader_id")
	end
	
end
