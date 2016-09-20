class AuditsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	layout 'full-width'

	def show
		if params[:pset_id]
			@pset = Pset.find(params[:pset_id])
		else
			@pset = Pset.order(:order).first
		end
		@psets = Pset.order(:order)
		@groups = Group.order(:name)
	end
	
	def mark_group_open
		@group = Group.find(params[:group_id])
		@group.grades.where(:submits => { :pset_id => params[:pset_id] }).update_all(:status => Grade.statuses[:open])
		redirect_to :back
	end

end
