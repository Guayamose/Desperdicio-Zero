# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "html5-qrcode", to: "https://ga.jspm.io/npm:html5-qrcode@2.3.8/esm/index.js"
pin_all_from "app/javascript/controllers", under: "controllers"
