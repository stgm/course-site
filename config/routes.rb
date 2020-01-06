Rails.application.routes.draw do

	# login
	get 'session/login', to: 'session#new'
	get 'session/logout', to: 'session#destroy'

	#--ADMIN------------------------------------------------------------------------------------

	namespace :admin do
		# site-wide settings, often used only once
		get 'site', to: 'site#index'
		namespace :site do
			get  'permissions'            #done
			post 'settings'               #done
			post 'set_git_repo'           #done
			post 'generate_secret'        #done
		end
		
		# dropbox linking
		namespace :dropbox do
			post "connect"
			get  "oauth"
		end

		# course settings, not often used
		get 'course', to: 'course#index'
		namespace :course do
			get   'export_grades'         #done
			patch 'schedule_registration' #done
			patch 'schedule_self_service' #done
			patch 'page_update'           #done
		end
		
		resources :users, only: [ :index ] do
			post   'add_group_permission'
			delete 'remove_group_permission'
			post   'add_schedule_permission'
			delete 'remove_schedule_permission'
			patch  'set_role'
		end
		
		resource :update, only: [ :create ]
	end

	#--BULK OPS---------------------------------------------------------------------------------

	resource :overview, module: 'schedules', as: 'schedule_overview', only: [ :show ]

	resources :schedules, module: 'schedules', param: 'slug', only: [] do

		get  "(/status/:status)", action: :index, as: '', defaults: { status: 'active' }
		
		resource :current_module, only: [ :update ]
		resource :export_final_grades, only: [ :new, :create ]
		resource :import_groups, only: [ :new, :create ]
		resource :generate_groups, only: [ :new, :create ]
		
		resources :grades, only: [] do
			collection do
				post "publish_finished"
				post "publish_my"
				post "publish_all"
				post "publish"
	
				get  "form_for_publish_auto"
				post "publish_auto"
	
				put  "assign_all_final"
			end
		end
		
		resources :submits, only: [] do
			collection do
				get  "form_for_late"
				post "close_and_mail_late"
				get  "form_for_missing"
				post "notify_missing"
			end
		end
		
		resource :status, only: [ :show ]
	end
	
	resources :groups, module: 'groups', only: [] do
		post 'reopen_grades'
	end
	
	#--APPS-------------------------------------------------------------------------------------
	
	# test management
	resources :tests, only: :index, shallow_prefix: 'tests', module: :tests do
		resource :results, only: [ :show, :update ]
		collection do
			resource :overview, as: 'test_overview', only: [ :show ]
		end
	end
	
	# grading interface
	resources :grading, param: 'submit_id', only: [ :index, :show, :create ], path: "grading" do
		get  "download"
	end
	# one button in the grading interface
	post "grading/finish", as: "finish_grading"
	
	# question queuing
	resources :hands, only: [ :index, :show, :new, :create, :update ], module: 'hands' do
		collection do
			# students
			resource :raise, as: 'hands_raise', only: [ :show, :create, :destroy ] do
				patch 'set_location'
			end
			# assistants
			resource :availability, as: 'hands_availability', only: [ :edit, :update ]
			# heads
			resource :statistics, as: 'hands_statistics', only: [ :show ]
		end
		member do
			put "dib"
			put "helpline"
			put "done"
		end
	end
	
	namespace :search do
		resource :users, only: [ :show ]
	end

	#--RESOURCES--------------------------------------------------------------------------------

	scope '/manage' do

		resources :users, only: [ :show, :update ] do
			post  "assign/:group_id", action: "assign_group", as: 'assign_group'
			post  "set_alarm/:alarm", action: "set_alarm", as: 'set_alarm'
			post  "calculate_final_grade"
			post  'schedule/:schedule_id', action: 'assign_schedule', as: 'assign_schedule'

			# resources :group_permissions, only: [ :index, :create, :destroy ]
		end

		resources :alerts
		resources :notes, only: [ :create ]
		resources :submits, only: [ :show, :create, :destroy ]
		resources :grades, except: [ :index ] do
			member do
				put  "templatize"
			end
		end

	end

	get  "profile" => "profile#index"
	namespace :profile do
		post 'save'
		get  'pair'
		post 'ask'
		get  'ping'
		get  'feedback/:submit_id', to: "profile#feedback", as: "profile_feedback"
		post 'next' # set user schedule
		post 'prev' # set user schedule
	end
	

	#--ONBOARDING-------------------------------------------------------------------------------
	# for new web site instances
	get  "welcome" => "welcome#index"
	get  "welcome/clone"
	get  "welcome/claim"
	get  "welcome/register"

	#--EXTERNAL APIs----------------------------------------------------------------------------

	post "api/reload"
	get  "api/current_longest_waiting_time"
	
	post "check_result/do"
	
	#--CONTENT----------------------------------------------------------------------------------

	# homepage
	root to: "home#homepage"
	get 'syllabus',      to: 'home#syllabus'
	get 'announcements', to: 'home#announcements'
	get 'submissions',   to: 'home#submissions'
	get 'staff',         to: 'home#staff'

	# search
	get  "search/autocomplete"
	get  "search/query"
	get  "search/subpage"

	# pages
	post "page/submit"
	get  ":section/:page" => "page#index" # default route, for content pages (must be 2nd last!)
	get  ":section" => "page#section"     # default route, for section pages (must be last!)

	# legacy mobile app support
	# namespace :tracking do
	# 	# for getting a token
	# 	post "register"                           => "register#identify"
	# 	# for getting info based on token id
	# 	post "tokenized/identify(/:token)"        => "tokenized#identify"
	# 	post "tokenized/ping(/:token)"            => "tokenized#ping"
	# 	post "tokenized/gone(/:token)"            => "tokenized#gone"
	# 	post "tokenized/help(/:token)"            => "tokenized#help"
	# 	post "tokenized/clear/:user"              => "tokenized#clear"
	# 	post "tokenized/list_assistants(/:token)" => "tokenized#list_assistants"
	# 	post "tokenized/list_students(/:token)"   => "tokenized#list_students"
	# end

end
