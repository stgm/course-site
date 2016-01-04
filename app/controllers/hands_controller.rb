class HandsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def index
		@my_hands = Hand.where(done:false, assist:current_user).order('created_at desc')
		@hands = Hand.where(done:false, assist:nil).order('created_at desc')
	end
	
	def dib
		# try to dib
		if hand = Hand.where(id: params[:which], assist: nil).first
			hand.update_attribute(:assist, current_user)
		end
		
		# check dib and report
		if Hand.find(params[:which]).assist == current_user
			flash[:notice] = "Taken!"
		else
			flash[:notice] = "Someone was ahead of you!"
		end
		
		redirect_to :back
	end

	def done
		Hand.find(params[:which]).update_attribute(:done, true)
		redirect_to :back
	end

end
