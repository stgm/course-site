class Tests::OverviewsController < ApplicationController

	before_action :authorize
	before_action :require_senior
	
	def show
		@psets = Pset.where(name: Settings['grading']['tests']['submits'].keys)
		@students = User.includes(submits: :grade).where(submits: { pset_id: @psets }).where("grades.calculated_grade = 0").order(:name)
		
		render layout: false
	end
	
end
