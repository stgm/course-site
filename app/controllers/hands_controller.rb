class HandsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def index
		redirect_to hands_available_path and return unless current_user.admin? || (current_user.available && current_user.available > DateTime.now)
		@my_hands = Hand.where(done:false, assist:current_user).order('created_at asc')
		@hands = Hand.where(done:false, assist:nil).order('created_at asc')
		@long_time_users = User.not_admin_or_assistant.where('last_seen_at > ? and (last_spoken_at < ? or last_spoken_at is null)', 25.minutes.ago, 2.days.ago).order('updated_at desc')
	end
	
	def show
		@hand = Hand.where(id: params[:id]).first
	end
	
	def student
		@user = User.where(id: params[:id]).first
	end
	
	def welcomed
		@user = User.where(id: params[:id]).first
		Hand.create(user_id: params[:id], evaluation: params[:evaluation], note: params[:note], done: true, assist: current_user)
		redirect_to action: 'index', only_path: true
	end
	
	def search
		@users = User.where("name like ?", "%#{params[:term]}%").not_admin_or_assistant
	end
	
	def dib
		# try to dib
		if hand = Hand.where(id: params[:which], assist: nil).first
			hand.update_attribute(:assist, current_user)
		end
		
		# check dib and report
		if Hand.find(params[:which]).assist == current_user
			flash[:notice] = "Taken, it's yours!"
			redirect_to :back
		else
			flash[:alert] = "Someone was ahead of you!"
			redirect_to ({ action: :index })
		end
	end

	def done
		h = Hand.find(params[:id])
		h.update_attributes(done: true, success:params[:success], evaluation: params[:evaluation], note: params[:note])
		if params[:success]
			AttendanceRecord.create_for_user(h.user)
		end
		redirect_to action: 'index', only_path: true
	end

end
