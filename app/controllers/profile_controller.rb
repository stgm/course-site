class ProfileController < ApplicationController

	before_action :authorize
		
	def index
		@title = "Profile"
	end
	
	def feedback
		submit = Submit.find(params[:submit_id])
		@formatted_feedback = submit.check_feedback_formatted
		respond_to do |format|
			format.js do
				render 'feedback'
			end
		end
	end
	
	def pair
		current_user.generate_pairing_code!
		render text: "Pairing code is #{"%04d" % current_user.token}"
	end
	
	def ping
		head :ok
	end
	
	def prev
		respond_to do |format|
			format.js do
				current_user.update(current_module: current_user.current_module.previous)
				@current_schedule = current_user.current_module
				render 'schedule'
			end
		end
	end
	
	def next
		respond_to do |format|
			format.js do
				current_user.update(current_module: current_user.current_module.next)
				@current_schedule = current_user.current_module
				render 'schedule'
			end
		end
	end
	
	def save # POST
		# remove leading and trailing space to give the user some slack
		params[:user][:name].strip!
		params[:user][:mail].strip!
		params[:user][:schedule_id] ||= Schedule.first.id
		
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
			# login = Login.where(login: session[:cas_user]).first_or_create
			# login.create_user and login.save if login.user.nil?
			# @current_user = login.user
			current_user.update!(params.require(:user).permit(:name, :mail, :schedule_id))
			current_user.student!
			current_user.logins.create(login: request.session['cas']['user'])
		end

		redirect_to :root
	end
	
	def ask
		if params[:how]
			if params[:how] == 'email'
				helpscout = HelpScout::Client.new(ENV['HELPSCOUT_API_KEY'])
				helpscout.create_conversation(
				{
					type: 'email',
					customer: {
						email: current_user.mail
					},
					subject: "New question from #{Settings.short_course_name}",
					mailbox: {
						id: 19905
					},
					tags: ['live'],
					threads: [
						{
							type: 'customer',
							createdBy: {
								email: current_user.mail,
								type: 'customer'
							},
							body: params['question']
						}
					]
				})
				# AskMailer.ask_me_anything(current_user, params['question'], request.remote_ip).deliver_later
				flash[:notice] = "Your question has been received! Expect an answer sometime soon."
			elsif params[:how] = 'hands'
				hand = Hand.create(user:current_user, help_question:params[:question], location:params[:location])
				flash[:notice] = "Your question has been received! Expect someone to arrive soon."
			end
		end
		redirect_back fallback_location: '/'
	end
	
end
