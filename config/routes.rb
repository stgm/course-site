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
	get  "admin/admins"
	post "admin/admins" => "admin#admins_save"
	post "admin/assistants" => "admin#assistants_save"
	get  "admin/dump_grades"
	get  "admin/stats"
	get  "admin/api"
	post "admin/api_save"
	
	namespace :admin do
		get  "dropbox" => "dropbox#index"
		post "dropbox/connect"
		get  "dropbox/oauth"
		post "dropbox/set_root_folder"
		
		get  "users/import"
		post "users/import_groups"
		get  "users/export_grades"
	end
	
	namespace :tracking do
		# for getting a token
		get  "register" => "register#identify"
		# for getting info based on token id
		get  "tokenized/identify(/:token)" => "tokenized#identify"
		get  "tokenized/ping(/:token)" => "tokenized#ping"
		get  "tokenized/gone(/:token)" => "tokenized#gone"
		get  "tokenized/help(/:token)" => "tokenized#help"
		get  "tokenized/list_assistants(/:token)" => "tokenized#list_assistants"
		get  "tokenized/list_students(/:token)" => "tokenized#list_students"
	end

	# course management
	get  "course/grades"
	get  "course/grades/:track" => "course#track_grades"
	post "course/touch_submit"
	post "course/toggle_public_grades"
	post "course/toggle_grading_allowed"
	post "course/toggle_send_grade_mails"
	post "course/import"
	post "course/add_student"
	post "course/remove_student"
	put  "course/change_user_name"

	# grading overview
	get  "grading" => "grading#index"

	# check off homework
	get  "check/:pset" => "check#index"

	# individual grades
	get  "grade/:user_id/:pset_id"      => "grades#form", as: 'grade_form'
	post "grade/:user_id/:pset_id/save" => "grades#save", as: 'grade_save'
	delete "grade" => "grades#destroy"
	
	# onboarding
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"

	# filled-in form caching for users
	post "page/save_answers"
	post "page/submit"
	post "page/prev_in_schedule"
	post "page/next_in_schedule"
	
	# api
	# get  "api/students"
	post "api/update_webhook"
	
	resource :user
	
	# default route, for content pages
	get  ":section/:page" => "page#index"

end
