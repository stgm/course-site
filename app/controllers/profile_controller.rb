class ProfileController < ApplicationController

	before_action :authorize
		
	def show
		@title = "Profile"
	end
	
	def feedback
		submit = Submit.find(params[:submit_id])
		@formatted_feedback = submit.formatted_auto_feedback
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
				render 'schedule'
			end
		end
	end
	
	def next
		respond_to do |format|
			format.js do
				current_user.update(current_module: current_user.current_module.next)
				render 'schedule'
			end
		end
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
			login = request.session['cas']['user'].downcase
			current_user.create_profile(user_params, login)
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
