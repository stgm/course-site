class AskController < ApplicationController

	before_action :authorize

	def do
		if Hand.where(user: current_user, done: false).count == 0
			hand = Hand.create(user:current_user, help_question:params[:question], subject: params[:subject], location:params[:location])
			current_user.update!(last_known_location: params[:location])
		end

		index
	end
	
	def set_location
		if !params[:location].blank?
			current_user.update!(last_known_location: params[:location])
		end
		
		# index
		respond_to do |format|
			format.html { redirect_to "/" }
			format.js { index }
		end
	end
	
	def index
		@assist_available = User.where('available > ?', DateTime.now)
		
		if @question = Hand.where(user: current_user, done: false).first
			if @question.assist.blank?
				waiting
			else
				helping
			end
		elsif is_local_ip? && current_user.student? && current_user.last_known_location.blank?
			location_small
		else
			form
		end
	end
	
	def location_small
	    # https://stackoverflow.com/questions/29997836/how-to-show-a-greeting-message-through-out-the-day
		
		current_time = Time.now.to_i
	    midnight = Time.now.beginning_of_day.to_i
	    noon = Time.now.middle_of_day.to_i
	    five_pm = Time.now.change(:hour => 17 ).to_i
	    eight_pm = Time.now.change(:hour => 20 ).to_i
		
		@greeting = case 
					when midnight.upto(noon).include?(current_time)
						"Good morning"
					when noon.upto(five_pm).include?(current_time)
						"Good afternoon"
					when five_pm.upto(eight_pm).include?(current_time)
						"Good evening"
					when eight_pm.upto(midnight + 1.day).include?(current_time)
						"Good night"
					end
		
		@assist_available = User.where('available > ?', DateTime.now)
		
		respond_to do |format|
			format.js { render 'location' }
		end
	end
	
	def location
		current_time = Time.now.to_i
	    midnight = Time.now.beginning_of_day.to_i
	    noon = Time.now.middle_of_day.to_i
	    five_pm = Time.now.change(:hour => 17 ).to_i
	    eight_pm = Time.now.change(:hour => 20 ).to_i
		
		@greeting = case 
					when midnight.upto(noon).include?(current_time)
						"Good morning"
					when noon.upto(five_pm).include?(current_time)
						"Good afternoon"
					when five_pm.upto(eight_pm).include?(current_time)
						"Good evening"
					when eight_pm.upto(midnight + 1.day).include?(current_time)
						"Good night"
					end
		
		@assist_available = User.where('available > ?', DateTime.now)
		
		respond_to do |format|
			format.html { render 'location', layout: 'welcome' }
		end
	end
	
	def form
		respond_to do |format|
			format.js { render 'form' }
		end
	end
	
	def cancel
		Hand.where(user: current_user, done: false).update_all(done: true, closed_at: DateTime.now)
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
