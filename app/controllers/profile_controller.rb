class ProfileController < ApplicationController

	before_action :authenticate

	include NavigationHelper

	def index
		if Schedule.none? || Schedule.default.present?
			render layout: 'welcome'
		else
			render 'sorry', layout: 'welcome'
		end
	end

	def show
		@title = "Profile"
	end

	def feedback
		submit = Submit.find(params[:submit_id])
		@formatted_feedback = submit.formatted_auto_feedback
		render_to_modal header: 'Check results'
	end

	def ping
		head :ok
	end

	def prev
		respond_to do |format|
			format.js do
				current_user.update(current_module: prev_module) if prev_module
				render 'schedule'
			end
		end
	end

	def next
		respond_to do |format|
			format.js do
				current_user.update(current_module: next_module) if next_module
				render 'schedule'
			end
		end
	end

	#
	# allows setting arbitrary settings in the settings model
	#
	def save_progress
		if items = params["progress"]
			items.each do |k,v|
				v = v == "1" if v == "1" or v == "0"
				current_user.progress[k] = v
				current_user.save
			end
		end
		head :ok
	end

	def save # POST
		# remove leading and trailing space to give the user some slack
		params[:user][:name].strip!
		params[:user][:mail].strip!

		# be explicit, but not so nice
		if params[:user][:name] !~ /^[^\s][^\s]+(\s+[^\s][^\s]+)+$/
			render plain: 'Will not work! Enter a valid name.'
			return
		end
		if params[:user][:mail] !~ /^[A-Za-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/
			render plain: 'Will not work! Enter a valid email address.'
			return
		end

		# create user if possible
		ActiveRecord::Base.transaction do
			user_params = params.require(:user).permit(:name, :mail, :schedule_id)
			login = request.session[:user_login]
			current_user.create_profile(user_params, login)
			session[:user_id] = current_user.id
		end

		redirect_to :root
	end

end
