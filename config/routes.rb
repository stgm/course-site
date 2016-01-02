Rails.application.routes.draw do

	resources :alerts

	# homepage
	root :to => "page#homepage"

	# logged-in users only
	get  "profile" => "profile#index"
	post "profile/save"
	get  "profile/grades"
	get  "profile/pair"
	get  "profile/logout"
	post "profile/ask"
	get  "profile/ping"

	# administrative
	get  "admin" => "admin#index"
	get  "admin/dump_grades"
	get  "admin/stats"
	get  "admin/import"
	post "admin/import_groups"
	get  "admin/export_grades"
	get  "admin/pages"
	put  "admin/page_update"
	get  "admin/schedule"
	post "admin/set_schedule"
	
	# configuration
	get  "config" => "config#index"
	get  "config/admins"
	get  "config/dropbox"
	get  "config/git"
	get  "config/webhook"

	post "config/admins"       => "config#admins_save"
	post "config/assistants"   => "config#assistants_save"
	post "config/git_repo"     => "config#git_repo_save"
	post "config/generate_secret"

	get  "admin/api"
	post "admin/api_save"

	# dropbox linking
	post "dropbox/connect"
	get  "dropbox/oauth"
	
	namespace :tracking do
		# for getting a token
		post "register"                           => "register#identify"
		# for getting info based on token id
		post "tokenized/identify(/:token)"        => "tokenized#identify"
		post "tokenized/ping(/:token)"            => "tokenized#ping"
		post "tokenized/gone(/:token)"            => "tokenized#gone"
		post "tokenized/help(/:token)"            => "tokenized#help"
		post "tokenized/clear/:user"              => "tokenized#clear"
		post "tokenized/list_assistants(/:token)" => "tokenized#list_assistants"
		post "tokenized/list_students(/:token)"   => "tokenized#list_students"
	end

	# course management
	get  "course/grades/admins"  , to: "course#grades_for_admins"
	get  "course/grades/other"   , to: "course#grades_for_other"
	get  "course/grades/inactive", to: "course#grades_for_inactive"
	get  "course/grades(/:group)", to: "course#grades_for_group", as: 'course_grades'
	post "course/touch_submit"
	post "course/import"
	post "course/remove_student"
	put  "course/change_user_name"
	put  "course/assign_final_grade"

	# grading overview
	get  "grading" => "grading#index"
	get  "grading/checklist" => "grading#checklist"
	
	get  "hands" => "hands#index"
	post "hands/dib"
	post "hands/done"

	# individual grades
	get  "grade/:user_id/:pset_id"      => "grades#form", as: 'grade_form'
	post "grade/:user_id/:pset_id/save" => "grades#save", as: 'grade_save'
	delete "grade" => "grades#destroy"
	post "grades/mark_all_done"
	post "grades/mark_all_public"
	
	# onboarding
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"

	# filled-in form caching for users
	post "page/submit"
	
	# api
	post "api/reload"
	
	resource :user
	
	mathjax 'mathjax'

	# default route, for content pages
	get  ":section/:page" => "page#index"

end
