class TestsController < ApplicationController

	before_action :authorize
	before_action :require_senior
	
	before_action :load_navigation
	before_action :load_schedule

	def index
		@psets = Pset.where(test: true).order(:order)
	end

	def show
		@pset = Pset.find_by_id(params[:id])
		@psets = Pset.all
		@students = User.student.order('lower(name)')
	end
	
	def overview
		@psets = Pset.where(name: Settings['grading']['tests']['submits'].keys)
		@students = User.includes(submits: :grade).where(submits: { pset_id: @psets }).where("grades.calculated_grade = 0").order(:name)
		
		render layout: false
	end
	
	def save
		# render text: params.inspect and return
		grades = params[:grades]
		pset_id = params[:test_id]
		
		grades.each do |user_id, info|
			notes = info[:notes]
			subgrades = info[:subgrades]
			# check if any of the subgrades has been filled
			if subgrades.values.map(&:present?).any?
				# logger.debug "#{user_id}  #{points}"
				s = Submit.where(user_id: user_id, pset_id: pset_id).first_or_create
				puts "That's submit #{s.id}"
				if g = s.grade
					subgrades.each do |name, value|
						g.subgrades[name] = value.to_i if value.present?
					end
					g.notes = notes
					# if anything's new, reset grade published-ness and save
					if g.changed?
						g.grader = current_user
						g.status = Grade.statuses[:finished]
						g.save
					end
				else
					g = s.build_grade(grader: current_user)
					subgrades.each do |name, value|
						g.subgrades[name] = value.to_i if value.present?
					end
					g.notes = notes
					g.status = Grade.statuses[:finished]
					g.save
				end
			end
		end
		
		redirect_back fallback_location: '/', notice: "Saved."
	end
	
end
