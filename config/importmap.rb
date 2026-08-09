# Pin npm packages by running ./bin/importmap

pin "application", to: "controllers.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/assets/controllers", under: "controllers", to: ""
pin "trix"
pin "@rails/actiontext", to: "actiontext.js"
