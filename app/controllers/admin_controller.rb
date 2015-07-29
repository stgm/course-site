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
	
	def stats
		# needs tracksssss
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
		# this is very dependent on datanose export format: id's in col 0 and 1, group name in 7
		if source = params[:paste]
			User.update_all(group_id: nil)
			Group.delete_all
		
			source.each_line do |line|
				next if line.strip == ""
				line = line.split("\t")

				user_id = line[0..1]
				group_name = line[7] && line[7].strip
				next if !group_name || group_name == "Group"
		
				user = User.where('uvanetid in (?)', user_id).first
				if user.present?
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
	
		redirect_to :back, notice: 'Student groups were successfully imported.'
	end

end
