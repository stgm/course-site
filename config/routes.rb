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
	post "course/touch_submit"
	post "course/import"
	post "course/remove_student"
	put  "course/change_user_name"
	put  "course/assign_final_grade"
	post "course/mark_all_public"
	
	# student tables for managers
	get  "students/in/admins"  , to: "students#list_admins"
	get  "students/in/other"   , to: "students#list_other"
	get  "students/in/inactive", to: "students#list_inactive"
	get  "students(/in/:group)", to: "students#list", as: 'students'
	resources :students, only: [ :show ]

	# grading overview for assistants
	# get  "grading" => "grading#index"
	
	namespace :hands do
		get "available" => "available#index"
		post "available/set" => "available#set"
	end

	get  "hands"              => "hands#index"
	get  "hands/search"       => "hands#search"
	get  "hands/student/:id"  => "hands#student"
	post "hands/welcomed/:id" => "hands#welcomed"
	post "hands/dib"
	post "hands/done"
	get  "hands/:id"          => "hands#show"
	
	post "grades/mark_all_done"
	
	resources :submits, only: [ :index, :create, :destroy ] do
		resource :grade, only: [ :show, :update ] do
			# post "mark_all_done"
		end
	end
	
	# onboarding
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"

	# filled-in form caching for users
	post "page/submit"
	get  "page/mobile_home"
	
	# api
	post "api/reload"
	
	resources :user do
		post "assign/:group_id", action: "assign_group", as: 'assign_group'
		post "calculate_final_grade"
	end
	
	mathjax 'mathjax'

	# default route, for content pages
	get  ":section/:page" => "page#index"

end
