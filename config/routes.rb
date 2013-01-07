CourseSite::Application.routes.draw do

	# homepage
	root :to => "page#homepage"

	# users only
	get "homepage/logout"
	get "homepage/profile"
	post "homepage/save_profile"

	# administrative
	post "admin/import_do"
	get "dropbox/link"

	resources :answers
	post "upload/submit"
	match ":section/:page" => "page#index"

end
