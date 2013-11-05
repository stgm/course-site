class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def create_submit
		@submit = Submit.create do |s|
			s.user_id = params[:user_id]
			s.pset_id = params[:pset_id]
		end
		redirect_to new_submit_grade_url(submit_id:@submit.id)
	end

	##
	# POST
	# ajax-only enable/disable of students
	#
	def enable
		reg = User.find(params[:id])
		reg.update_attribute(:active, params[:active])
		render :nothing => true
	end

	##
	# POST
	# ajax-only done/not done of students
	#
	def done
		reg = User.find(params[:id])
		reg.update_attribute(:done, params[:done])
		render :nothing => true
	end
	
	def export
		@users = User.where(active: true).order('name')
		@psets = Pset.order(:id)
		@title = "Export grades"
	end
		
	# GET /grades
	# GET /grades.json
	def index
		@submits = Submit.includes(:user, :pset, :grade).where("users.active = ? and users.done = ? and (grades.updated_at < submits.updated_at or grades.updated_at is null or grades.updated_at > ?)", true, false, 5.days.ago).order('psets.name')
	end
	
	def check
		pset_id = 'hw2'
		@pset = Pset.where(name:pset_id).first
		existing_grades = Grade.joins(:submit => :user).where("submits.pset_id = ?", @pset.id).pluck("users.uvanetid")
		if(existing_grades.count > 0)
			@users = User.where('uvanetid not in (?)', existing_grades)
		else
			@users = User.all
		end
	end

	# GET /grades/1
	# GET /grades/1.json
	def show
		@grade = Submit.find(params[:submit_id]).grade

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @grade }
		end
	end

	# GET /grades/new
	# GET /grades/new.json
	def new
		@submit = Submit.find(params[:submit_id])
		@grade = @submit.build_grade do |e|
			e.grader = current_user.uvanetid
		end
		@grades = Grade.includes(:submit).where("submits.user_id = ?", @submit.user_id)

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @grade }
		end
	end

	# GET /grades/1/edit
	def edit
		@submit = Submit.find(params[:submit_id])
		@grade = @submit.grade
		@grades = Grade.includes(:submit).where("submits.user_id = ?", @submit.user_id)
		logger.info @grade.inspect
	end

	# POST /grades
	# POST /grades.json
	def create
		@grade = Grade.new(params[:grade])
		@grade.submit_id = params[:submit_id]
		@grade.grader = current_user.uvanetid

		respond_to do |format|
			if @grade.save
				format.html { redirect_to grades_url, notice: 'Grade was successfully created.' }
				format.json { render json: @grade, status: :created, location: @grade }
			else
				format.html { render action: "new" }
				format.json { render json: @grade.errors, status: :unprocessable_entity }
			end
		end
	end

	# PUT /grades/1
	# PUT /grades/1.json
	def update
		@grade = Submit.find(params[:submit_id]).grade

		respond_to do |format|
			if @grade.update_attributes(params[:grade])
				format.html { redirect_to grades_url, notice: 'Grade was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @grade.errors, status: :unprocessable_entity }
			end
		end
	end
	
	def create_or_update
		# @pset = Pset.find(params[:pset_id])
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first_or_create
		if @submit.grade
			@submit.grade.update_attributes(params[:grade])
		else
			@submit.create_grade(params[:grade])
			@submit.grade.update_attribute(:grader, current_user.uvanetid)
		end
		render nothing: true
	end

	# DELETE /grades/1
	# DELETE /grades/1.json
	def destroy
		@grade = Submit.find(params[:submit_id]).grade
		@grade.destroy

		respond_to do |format|
			format.html { redirect_to grades_url }
			format.json { head :no_content }
		end
	end

end
