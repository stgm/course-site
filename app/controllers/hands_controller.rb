class HandsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff

	def index
		redirect_to hands_available_path and return unless current_user.admin? || (current_user.available && current_user.available > DateTime.now)
		@my_hands = Hand.where(done:false, assist:current_user).order('created_at asc')
		@hands = Hand.where(done:false, assist:nil).order('created_at asc')
		@long_time_users = User.student.where('last_seen_at > ? and (last_spoken_at < ? or last_spoken_at is null)', 25.minutes.ago, 2.days.ago).order('updated_at desc')
	end
	
	def show
		if current_user.assistant? and @hand.assist.blank? and !@hand.helpline
			Hand.where(id: params[:id], assist: nil).update_all(assist_id: current_user.id)

			@hand = Hand.where(id: params[:id]).first

			# check dib and report
			if @hand.assist == current_user
				flash[:notice] = "Taken, it's yours!"
			else
				flash[:alert] = "Someone was ahead of you!"
				redirect_to ({ action: :index })
			end
		else
			@hand = Hand.where(id: params[:id]).first
			
		end
		
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
		@users = User.where("name like ?", "%#{params[:term]}%").student
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

	def helpline
		h = Hand.find(params[:id])
		h.update_attributes(helpline: true, assist: nil)
		AttendanceRecord.create_for_user(h.user)
		redirect_to action: 'index', only_path: true
	end

end
