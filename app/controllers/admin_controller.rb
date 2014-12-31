class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def dump_grades
		@students = User.order(:name)
		# @grades = Grade.joins(:submit).includes(:submit => [:pset,:user]).where("grades.submit_id is not null").order("psets.name")
		render layout:nil
	end
	
	def stats
		# needs tracksssss
		@terms = User.select("distinct term")
		render layout: nil
	end
		
end
