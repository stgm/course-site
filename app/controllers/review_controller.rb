class ReviewController < ApplicationController

	before_action :login_required
	before_action :require_senior
	
	layout "full-width"

	def index
		# @users = current_user.schedule.users.includes(submits: [:grade, :pset]).where("grades.status in (?)", [Grade.statuses[:open], Grade.statuses[:finished]]).references(:grades).order("grades.grader_id")
		
		@data = current_user.schedule.grades.includes(:grader, submit: :pset).where("grades.status in (?)", [Grade.statuses[:open], Grade.statuses[:finished]]).order("grades.grader_id").group_by(&:grader)
	end
	
end
