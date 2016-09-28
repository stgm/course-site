class AskController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter

	def do
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
				# flash[:notice] = "Your question has been received! Expect an answer sometime soon."
			elsif params[:how] = 'hands'
				hand = Hand.create(user:current_user, help_question:params[:question], location:params[:location])
				if Features.slack_integration?
					notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], channel: Settings.hands_slack_channel
					notifier.ping "*#{hand.user.name}* needs help at *#{hand.location}* <#{hands_url}|dibs!>\n#{hand.help_question}"
				end
				# flash[:notice] = "Your question has been received! Expect someone to arrive soon."
			end
		end

		index
	end
	
	def index
		@assist_available = User.where('available > ?', DateTime.now)
		
		if @question = Hand.where(user: current_user, done: false).first
			if @question.assist.blank?
				waiting
			else
				helping
			end
		else
			form
		end
	end
	
	def form
		respond_to do |format|
			format.js { render 'form' }
		end
	end
	
	def waiting
		@number = Hand.where(done:false, assist:nil).where("created_at < (?)", @question.created_at).count + 1
		
		respond_to do |format|
			format.js { render 'waiting' }
		end
	end
	
	def helping
		@hand = Hand.where(user: current_user, done: false).where.not(assist: nil).first
		@assist = @hand.assist
		
		respond_to do |format|
			format.js { render 'helping' }
		end
	end
	
end
