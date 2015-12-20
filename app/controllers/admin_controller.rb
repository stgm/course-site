class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def export_grades
		@users = User.where(active: true).order('name')
		@psets = Pset.order(:id)
		@title = "Export grades"
		render layout: false
	end
	
	def dump_grades
		@students = User.order(:name)
		render layout: false
	end
	
	def pages
		@all_sections = Section.includes(pages: :pset)
	end
	
	def page_update
		p = Page.find(params[:id])
		p.update!(params.require(:page).permit(:public))
		render json: p
	end
	
	def schedule
		@schedules = ScheduleSpan.all
		@schedule_position = Settings.schedule_position && ScheduleSpan.find(Settings.schedule_position) || ScheduleSpan.new
		logger.info @schedule_position.id
	end
	
	def set_schedule
		Settings.schedule_position = params[:id]
		render json: nil
	end
	
	def stats
		@gestart = User.joins(:submits).uniq.count
		final = Pset.find_by_name('final')
		@gehaald = User.joins(:grades => :submit).where('submits.pset_id = ?', final).uniq.count
		logger.debug @gehaald.inspect
		@terms = User.select("distinct term")
		render layout: false
	end
		
	#
	# divide users into groups from a csv
	#
	def import_groups
		# this is very dependent on datanose export format: ids in col 0 and 1, group name in 7
		if source = params[:paste]
			User.update_all(group_id: nil)
			Group.delete_all
		
			source.each_line do |line|
				next if line.strip == ""
				line = line.split("\t")

				user_id = line[0..1]
				group_name = line[7] && line[7].strip
				user_name = line[3] + " " + line[2].split(",").reverse.join(" ")
				user_mail = line[4] && line[4].strip
				next if !group_name || group_name == "Group"

				if user_id[0] == user_id[1]
					login = Login.where(login: user_id[0]).first_or_create
					user = login.user or (user = login.create_user and login.save)
					user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
					if group_name != ""
						group = Group.where(:name => group_name).first_or_create
						user.group = group
						user.save
					else
						user.group = nil
						user.save
					end
				else
					first_user = User.with_login(user_id[0]).first
					second_user = User.with_login(user_id[1]).first
					if first_user.nil? && second_user.nil?
						login = Login.where(login: user_id[0]).first_or_create
						user = login.user or (user = login.create_user and login.save)
						login2 = Login.where(login: user_id[1]).first_or_create
						login2.user = login.user and login2.save
						user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
						if group_name != ""
							group = Group.where(:name => group_name).first_or_create
							user.group = group
							user.save
						else
							user.group = nil
							user.save
						end
					elsif first_user == second_user
						user = first_user
						if group_name != ""
							group = Group.where(:name => group_name).first_or_create
							user.group = group
							user.save
						else
							user.group = nil
							user.save
						end
					elsif first_user.nil?
						login = Login.where(login: user_id[0]).first_or_create
						login.user = second_user and login.save
						user = second_user
						if group_name != ""
							group = Group.where(:name => group_name).first_or_create
							user.group = group
							user.save
						else
							user.group = nil
							user.save
						end						
					elsif second_user.nil?
						login = Login.where(login: user_id[1]).first_or_create
						login.user = first_user and login.save
						user = first_user
						if group_name != ""
							group = Group.where(:name => group_name).first_or_create
							user.group = group
							user.save
						else
							user.group = nil
							user.save
						end						
					end
				end
			end
		end
	
		redirect_to :back, notice: 'Student groups were successfully imported.'
	end

end
