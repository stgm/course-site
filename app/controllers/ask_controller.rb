class AskController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter

	def do
		if params[:how]
			if params[:how] = 'hands'
				hand = Hand.create(user:current_user, help_question:params[:question], location:params[:location])
				if Features.slack_integration?
					notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], channel: Settings.hands_slack_channel
					notifier.ping "*#{hand.user.name}* needs help at *#{hand.location}* <#{hands_url}|dibs!>\n#{hand.help_question}"
				end
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
	
	def cancel
		Hand.where(user: current_user, done: false).update_all(done: true)
		index
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
