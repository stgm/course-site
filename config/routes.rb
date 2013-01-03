CourseSite::Application.routes.draw do

	# homepage
	root :to => "page#homepage"
	get "homepage/logout"

	# administrative
	post "admin/import_do"
	get "dropbox/link"

	resources :answers
	post "upload/submit"
	match ":section/:page" => "page#index"

end
