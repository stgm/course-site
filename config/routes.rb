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
	get  "admin/generate_groups(/:schedule_id)", to: "admin#generate_groups", as: "admin_generate_groups"
	post "admin/generate_groups_do(/:schedule_id)", to: "admin#generate_groups_do", as: "admin_generate_groups_do"
	get  "admin/export_grades"
	get  "admin/pages"
	put  "admin/page_update"
	put  "admin/section_update"
	put  "admin/schedule_set_self_register"
	get  "admin/schedule"
	post "admin/set_schedule"
	
	get  "stats/hands"
	
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
	post "course/import"
	
	# student tables for managers
	put  "students/assign_final_grade"
	post "students/mark_all_public"
	post "students/mark_my_public"
	post "students/mark_everything_public"
	get  "students/late_form"
	post "students/close_and_mail_late"
	get  "students/notify_non_submits"
	post "students/notify_non_submits_do"
	get  "students/in/admins"  , to: "students#list_admins"
	get  "students/in/other"   , to: "students#list_other"
	get  "students/in/inactive", to: "students#list_inactive"
	get  "students/in/:group"  , to: "students#index", as: :students_in_group
	get  "students", to: "students#index"
	
	get "status" => "status#index"

	resources :user, only: [ :show, :update ] do
		# member do
			put "touch_submit"
			post "assign/:group_id", action: "assign_group", as: 'assign_group'
			post "schedule/:schedule_id", action: "assign_schedule", as: 'assign_schedule'
			post "set_alarm/:alarm", action: "set_alarm", as: 'set_alarm'
			post "calculate_final_grade"
		# end
	end

	# grading overview for assistants
	# get  "grading" => "grading#index"
	
	resource :audit, only: [ :show ] do
	end
	post "mark_group_open/(:group_id)/(:pset_id)", to: "audits#mark_group_open", as: "audit_mark_group_open"
	
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
	
	post "submits/mark_all_done"
	get  "submits/discuss"
	resources :submits, only: [ :index, :create, :destroy ] do
		resource :grade, only: [ :show, :update ] do
			# post "mark_all_done"
		end
	end
	
	resources :notes
	
	# onboarding
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"

	# filled-in form caching for users
	post "page/submit"
	get  "page/mobile_home"
	
	# api
	post "api/reload"
	
	mathjax 'mathjax'

	# default route, for content pages
	get  ":section/:page" => "page#index"

end
