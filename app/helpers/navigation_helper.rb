module NavigationHelper

	def current_sections
		if current_user.staff?
			Settings.page_tree || {}
		else
			# TODO hide hidden pages
			Settings.page_tree || {}
		end
	end

	def current_schedule
		@current_schedule ||= current_user.try :check_current_schedule!
	end

	def current_module
		if current_schedule
			@current_module ||= if current_schedule.self_service
				current_user.check_current_module!
			else
				current_schedule.current
			end
		end
	end

	def prev_module
		# retrieve previous module from here, accounting for student/admin permissions
		current_user.current_module&.previous(current_user.student?)
	end

	def next_module
		# retrieve next module from here, accounting for student/admin permissions
		current_user.current_module&.next(current_user.student?)
	end

	def alerts_for_current_schedule
		Alert.having_schedule_or_nil(current_schedule).where(published: true)
	end

end
