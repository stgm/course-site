CourseSite::Application.routes.draw do

	# homepage
	root :to => "page#homepage"

	# logged-in users only
	get  "homepage/logout"
	get  "homepage/profile"
	post "homepage/save_profile"

	# administrative
	get  "admin/users"
	get  "admin/claim"
	get  "admin/dropbox"
	post "admin/dropbox" => "admin#dropbox_save"
	get  "admin/admins"
	post "admin/admins" => "admin#admins_save"
	post "admin/import_do"
	post "admin/import_groups"
	get  "dropbox/link"

	# commenting
	post "comment/post_question"
	post "comment/post_answer"
	post "comment/delete_question"
	post "comment/delete_answer"

	resources :answers
	post "upload/submit"
	match ":section/:page" => "page#index"
	

end
