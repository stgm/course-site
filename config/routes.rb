CourseSite::Application.routes.draw do

	resources :submits do
		resource :grade
	end

	# homepage
	root :to => "page#homepage"

	# logged-in users only
	get  "profile" => "profile#index"
	post "profile/save"
	get  "profile/logout"

	# administrative
	get  "admin/users"
	get  "admin/claim"
	get  "admin/dropbox"
	post "admin/dropbox" => "admin#dropbox_save"
	get  "admin/link"
	get  "admin/admins"
	post "admin/admins" => "admin#admins_save"
	post "admin/assistants" => "admin#assistants_save"
	post "admin/import_do"
	post "admin/import_groups"
	post "admin/done"
	post "admin/enable"
	post "admin/create_submit"

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
