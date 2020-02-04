class Hands::HandsController < ApplicationController

	before_action :authorize
	before_action :require_staff
	
	layout 'hands'
	
	def index
		redirect_to edit_hands_availability_path and return unless current_user.senior? || (current_user.available && current_user.available > DateTime.now)
		
		if params[:term]
			@users = User.where("name like ?", "%#{params[:term]}%").student
			render 'search'
		else
			@my_hands = Hand.where(done:false, assist:current_user).order('created_at asc')
			@hands = Hand.where(done:false, assist:nil).order('created_at asc')
			@long_time_users = User.student.where("last_known_location is not null").where('last_seen_at > ? and (last_spoken_at < ? or last_spoken_at is null)', 25.minutes.ago, 1.day.ago).order('last_spoken_at asc')
		end
	end
	
	# showing a hand automatically dibs/claims it, only for assistant users
	def show
		# catch erroneous GET requests for /hands/done
		raise ActionController::RoutingError.new("Huh?") if params[:id] == "done"
		
		Hand.transaction do
			load_hand
			if current_user.assistant? && @hand.assist != current_user && !@hand.helpline
				if auto_claim_hand
					flash[:notice] = "Taken, it's yours!"
				else
					flash[:alert] = "Someone was ahead of you!"
					redirect_to hands_path and return
				end
			end
		end
	end
	
	def new
		load_user
	end
	
	def create
		load_user
		create_hand
		redirect_to action: 'index', only_path: true
	end
	
	def search
	end
	
	# manual dibs for admins & other situations
	def dib
		Hand.transaction do
			load_hand
			if auto_claim_hand
				flash[:notice] = "Taken, it's yours!"
				redirect_back fallback_location: '/'
			else
				flash[:alert] = "Someone was ahead of you!"
				redirect_to hands_path and return
			end
		end
	end

	def done
		h = Hand.find(params[:id])
		h.update_attributes(done: true, success:params[:success], evaluation: params[:evaluation], note: params[:note], progress: params[:progress], closed_at: DateTime.now)
		redirect_to action: 'index', only_path: true
	end

	def helpline
		h = Hand.find(params[:id])
		h.update_attributes(helpline: true, assist: nil)
		redirect_to action: 'index', only_path: true
	end
	
	private
	
	def load_user
		@user = User.find(params[:user_id])
	end
	
	def load_hand
		@hand = Hand.find(params[:id])
	end
	
	def auto_claim_hand
		if @hand.assist.blank?
			@hand.update(assist_id: current_user.id, claimed_at: DateTime.now)
			return true
		end
	end

	def create_hand
		Hand.create(user_id: @user.id, evaluation: params[:evaluation], note: params[:note], done: true, success:true, assist: current_user, progress: params[:progress], closed_at: DateTime.now)
	end

end
