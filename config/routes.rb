CourseSite::Application.routes.draw do

	# homepage
	root :to => "page#homepage"

	# logged-in users only
	get  "profile" => "profile#index"
	post "profile/save"
	get  "profile/grades"
	get  "profile/logout"

	# administrative
	get  "admin/claim"
	get  "admin/admins"
	post "admin/admins" => "admin#admins_save"
	post "admin/assistants" => "admin#assistants_save"

	# course management
	get  "course/grades"
	post "course/import"
	post "course/import_groups"

	# dropbox
	get  "dropbox" => "dropbox#index"
	post "dropbox/connect"
	get  "dropbox/oauth"

	# grading
	get  "grades" => "grades#index"
	get  "grades/export"
	post "grades/create_submit"
	post "grades/done"
	post "grades/enable"
	resources :submits do
		resource :grade
	end

	# commenting
	post "comment/post_question"
	post "comment/post_answer"
	post "comment/delete_question"
	post "comment/delete_answer"
	
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
