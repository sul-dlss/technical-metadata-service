# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin 'bootstrap', to: 'https://ga.jspm.io/npm:bootstrap@4.4.1/dist/js/bootstrap.js'
pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@3.6.0/dist/jquery.js'
pin 'popper.js', to: 'https://ga.jspm.io/npm:popper.js@1.16.1/dist/umd/popper.js'
