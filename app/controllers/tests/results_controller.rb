class Tests::ResultsController < Tests::TestsController

	before_action :authorize
	before_action :require_senior
	before_action :load_navigation
	
	def index
		@psets = Pset.where(test: true).order(:order)
		render_to_modal header: 'Test administration'
	end

	def show
		@pset = Pset.find_by_id(params[:test_id])
		@psets = Pset.all
		@students = User.student.order('lower(name)')
		render_to_modal header: @pset.name.titleize
	end

	def update
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
		
		respond_to do |format|
			format.js { head :ok }
			format.html { redirect_back fallback_location: '/', notice: "Saved." }
		end
	end
	
end
