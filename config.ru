require 'sinatra/base'
Dir.glob('./app/{helpers,controllers}/*.rb').each { |file| require file }

map('/') { run LoginController }
map('/authentication') { run AuthenticationController }
map('/portal') { run PortalController }
map('/plocater') { run PLocaterController }
map('/elocater') { run ELocaterController }
map('/cglocater') { run CGLocaterController }
