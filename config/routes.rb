Rails.application.routes.draw do

    root to: "home#index"

    #--LOGIN------------------------------------------------------------------------------------

    namespace :auth do
        namespace :session do
            get "logout"
        end
        namespace :open do
            get "login"
            get "callback"
        end
        namespace :mail do
            post "create"
            get "code"
            post "validate"
            get "login"
        end
        namespace :pin do
            get "login"
            post "validate"
        end
    end

    #--ADMIN------------------------------------------------------------------------------------

    namespace :admin do
        mount MissionControl::Jobs::Engine, at: "/jobs"

        # site-wide settings, often used only once
        get "site", to: "site#index"
        namespace :site do
            get	 "permissions"			  # done
            post "settings"				  # done
            post "set_git_repo"			  # done
            post "set_git_version"		  # done
            post "generate_secret"		  # done
        end

        # course settings, not often used
        get "course", to: "course#index"
        namespace :course do
            get	  "export_grades"		  # done
            patch "schedule_registration" # done
            patch "schedule_self_service" # done
            patch "page_update"			  # done
            patch "update_schedule_span"
        end

        resources :users, only: [ :index, :new, :create ] do
            post   "add_group_permission"
            delete "remove_group_permission"
            post   "add_schedule_permission"
            delete "remove_schedule_permission"
            patch  "set_role"
            put	   "set_role"
        end

        resource :update, only: [ :create ]
    end

    #--BULK OPS---------------------------------------------------------------------------------

    resources :overviews, only: [ :index ] do
        member do
            get "/status/:status", to: "overviews#show", as: "", defaults: { status: "active" }
        end
    end

    resources :schedules, module: "schedules", param: "slug", only: [] do
        get "(/status/:status)", action: :index, as: "", defaults: { status: "active" }

        resource :current_module, only: [ :edit, :update ]
        resource :export_final_grades, only: [ :new, :create ]
        resource :import_groups, only: [ :new, :create ] do
            post "propose"
        end
        resource :generate_groups, only: [ :new, :create ]
        resource :add_group, only: [ :new, :create ]

        resources :grades, only: [] do
            collection do
                post "publish_finished"
                post "publish_my"
                post "publish_all"
                post "publish"

                get	 "form_for_publish_auto"
                post "publish_auto"

                put	 "assign_all_final"
                post "reopen", param: "group_id"
            end
        end

        resources :submits, only: [] do
            collection do
                get	 "form_for_late"
                post "close_and_mail_late"
                get	 "form_for_missing"
                post "notify_missing"
                post "recheck"
            end
        end

        resource :status, only: [ :show ]
    end

    #--APPS-------------------------------------------------------------------------------------

    # test management
    resources :tests, only: :index, shallow_prefix: "tests", module: :tests do
        resource :results, only: [ :show, :update ]
        collection do
            resource :overview, as: "test_overview", only: [ :show ]
        end
    end

    # grading interface
    resources :grading, param: "submit_id", only: [ :index, :show, :create ], path: "grading" do
        get "download"
    end
    # one button in the grading interface
    post "grading/finish", as: "finish_grading"

    # question queuing
    resources :hands, only: [ :index, :show, :new, :create, :update ], module: "hands" do
        collection do
            # students
            resource :raise, as: "hands_raise", only: [ :show, :create, :destroy ] do
                patch "set_location"
            end
            # assistants
            resource :availability, as: "hands_availability", only: [ :edit, :update ]
            # heads
            resource :statistics, as: "hands_statistics", only: [ :show ]
        end
        member do
            put "dib"
            put "helpline"
            put "done"
        end
    end

    resources :questions
    resources :answers

    resources :assistance, only: [ :index ]

    #--RESOURCES--------------------------------------------------------------------------------

    scope path: "/manage" do
        resources :users, only: [ :index, :show, :edit, :update ] do
            collection do
                get "search"
            end
            member do
                post  "calculate_final_grade"
            end
        end

        resources :alerts
        resources :notes, only: [ :index, :show, :create, :edit, :update ]

        resources :grades, only: [ :destroy ] do
            member do
                patch "publish"
                patch "reopen"
                patch "reject"
            end
        end
    end

    resources :submits, only: [ :show, :create, :destroy, :update ] do
        member do
            post "recheck"
            get  "download"
        end
    end

    # creation is done via submit
    resources :git_repos, only: [ :show ]

    get "profile" => "profile#index"
    namespace :profile do
        post "save"
        get	 "pair"
        post "ask"
        get	 "ping"
        post "next" # set user schedule
        post "prev" # set user schedule
        post "set_module"
        post "save_progress"
        patch "set_schedule"
    end

    resource :todo do
        get "watch_list"
        get "show"
    end

    resources :exams, only: [ :index ] do
        member do
            post "create"
            post "post"
            get  "json"
        end
    end

    namespace :admin do
        resources :exams, only: [ :show, :index, :edit, :update ] do
            collection do
                post "start_exam_mode"
                post "stop_exam_mode"
                post "assign_codes"
                get "list_codes"
            end
            member do
                post "run_checks"
                patch "toggle"
                patch "toggle_student"
            end
        end
    end

    #--EXTERNAL APIs----------------------------------------------------------------------------

    post "api/reload", to: "api/api#reload"
    get	 "api/current_longest_waiting_time"

    post "api/check_result/do", to: "api/check_result#do"

    namespace :api do
        resources :test_results, only: [ :create ]
    end

    post "/git_repos/:id/webhook", to: "api/git_repo_webhooks#receive"

    #--CONTENT----------------------------------------------------------------------------------

    # homepage
    get "manifest.json", to: "home#manifest"
    get "home/clone"
    get "syllabus",		 to: "page#index", defaults: { slug: "syllabus" }
    get "announcements", to: "page#announcements"

    # search
    get	 "search/autocomplete"
    get	 "search/query"
    get	 "search/subpage"

    # pages
    resources :submissions, only: [ :index, :create ] do
        get "feedback"
        get "download"
    end

    get	 "s/*slug" => "page#submit", as: "page_submit"
    get	 "q/syllabus" => "page#questions", defaults: { slug: "syllabus" }
    get	 "q/*slug" => "page#questions"

    # default route, for content pages (must be last!)
    # ..with an exception for the /rails routes
    get	 "*slug" => "page#index", constraints: lambda { |e| !e.fullpath.start_with?("/rails/") }
end
