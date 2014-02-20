CourseSite::Application.routes.draw do

	# homepage
	root :to => "page#homepage"

	# logged-in users only
	get  "profile" => "profile#index"
	post "profile/save"
	get  "profile/grades"
	get  "profile/logout"

	# administrative
	get  "admin" => "admin#index"
	get  "admin/claim"
	get  "admin/import_users"
	get  "admin/admins"
	post "admin/admins" => "admin#admins_save"
	post "admin/assistants" => "admin#assistants_save"
	get  "admin/dump_grades"
	get  "admin/stats"

	# course management
	get  "course/grades"
	get  "course/grades/:track" => "course#track_grades"
	get  "course/export_grades"
	post "course/done"
	post "course/enable"
	post "course/touch_submit"
	post "course/toggle_public_grades"
	post "course/toggle_grading_allowed"
	post "course/import"
	post "course/import_groups"

	# dropbox
	get  "dropbox" => "dropbox#index"
	post "dropbox/connect"
	get  "dropbox/oauth"

	# grading overview
	get  "grading" => "grading#index"

	# check off homework
	get  "check/:pset" => "check#index"

	# individual grades
	get  "grade/:user_id/:pset_id"      => "grades#form", as: 'grade_form'
	post "grade/:user_id/:pset_id/save" => "grades#save", as: 'grade_save'
	
	# commenting
	# post "comment/post_question"
	# post "comment/post_answer"
	# post "comment/delete_question"
	# post "comment/delete_answer"
	
	# onboarding
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"

	# filled-in form caching for users
	post "page/save_answers"
	post "page/submit"
	
	# default route, for content pages
	match ":section/:page" => "page#index"

end
