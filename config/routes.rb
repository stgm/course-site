Rails.application.routes.draw do

	resources :alerts

	# homepage
	root :to => "page#homepage"
	get "syllabus", to: "page#syllabus"
	get "announcements", to: "page#announcements"

	# logged-in users only
	get  "profile" => "profile#index"
	post "profile/save"
	get  "profile/pair"
	get  "profile/logout"
	post "profile/ask"
	get  "profile/ping"
	get  "profile/feedback/:submit_id", to: "profile#feedback", as: "profile_feedback"

	# set user schedule
	post "profile/next"
	post "profile/prev"

	# administrative
	get  "admin" => "admin#index"
	get  "admin/dump_grades"
	get  "admin/stats"
	get  "admin/import"
	post "admin/import_groups"
	get  "admin/generate_groups(/:schedule_id)", to: "admin#generate_groups", as: "admin_generate_groups"
	post "admin/generate_groups_do(/:schedule_id)", to: "admin#generate_groups_do", as: "admin_generate_groups_do"
	get  "admin/export_grades"
	get  "admin/schedule"
	post "admin/set_schedule"
	
	get  "stats/hands"
	
	# configuration
	get  "config" => "config#index"
	get  "config/admins"
	get  "config/dropbox"
	get  "config/git"
	get  "config/webhook"
	get  "config/permissions"

	post "config/admins"       => "config#admins_save"
	post "config/assistants"   => "config#assistants_save"
	post "config/git_repo"     => "config#git_repo_save"
	post "config/generate_secret"
	post "config/settings"
	put  "config/schedule_registration"
	patch  "config/schedule_self_service"
	put  "config/page_update"
	put  "config/section_update"

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
	post "course/import"
	
	# student tables for managers
	get  "students/in/admins"  , to: "students#list_admins"
	get  "students/in/other"   , to: "students#list_other"
	get  "students/in/inactive", to: "students#list_inactive"
	get  "students/in/:group(/are/:status)"  , to: "students#index", as: :students_in_group, defaults: { status: 'active' }
	get  "students(/that/are/:status)", to: "students#index", as: :students, defaults: { status: 'active' }
	get  "students/find"
	
	get "students/quiz"
	post "students/quiz_submit"
	
	get "status" => "status#index"

	resources :user, only: [ :show, :update ] do
		# member do
			patch "set_permissions"
			patch "remove_permissions"
			put "admin"
			put "touch_submit"
			post "assign/:group_id", action: "assign_group", as: 'assign_group'
			post "schedule/:schedule_id", action: "assign_schedule", as: 'assign_schedule'
			post "set_alarm/:alarm", action: "set_alarm", as: 'set_alarm'
			post "calculate_final_grade"
		# end
	end
	
	namespace :hands do
		get "available" => "available#index"
		post "available/set" => "available#set"
	end

	get  "ask" => "ask#index"
	post "ask/do"
	post "ask/set_location"
	post "ask/cancel"
	
	get  "hands"              => "hands#index"
	get  "hands/search"       => "hands#search"
	get  "hands/student/:id"  => "hands#student"
	post "hands/welcomed/:id" => "hands#welcomed"
	post "hands/dib"
	post "hands/done"
	post "hands/helpline"
	get  "hands/:id"          => "hands#show"

	resources :submits, only: [ :index, :show, :create, :destroy ], path: "grading" do
		# the grade that belongs to a specific submit
		# resource :grade, only: [ :show, :update ]
		
		member do
			get  "download"
		end
		
		collection do
			post "finish"
			
			
			get  "form_for_late"
			post "close_and_mail_late"
			get  "form_for_missing"
			post "notify_missing"
			
		end
	end
	
	resources :grades do
		member do
			put  "templatize"
		end
				
		collection do
			post "publish_finished"
			post "publish_mine"
			post "publish_all"
			post "publish"
			put  "assign_all_final"
			post "reopen/(:group_id)", to: "grades#reopen", as: "reopen"
		end
	end
	
	resources :review
	
	resources :notes
	
	# onboarding
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"
	get  "welcome/register"

	# filled-in form caching for users
	post "page/submit"
	
	# api
	post "api/reload"
	
	mathjax 'mathjax'

	# default route, for content pages
	get  ":section/:page" => "page#index"

end
