require 'rubygems' if RUBY_VERSION.to_f < 1.9
	require 'sinatra/base'
require 'haml'

require 'json'

require File.expand_path("musictab/version",File.dirname(__FILE__))
require File.expand_path("musictab/db_wrap",File.dirname(__FILE__))
require File.expand_path("musictab/fops",File.dirname(__FILE__))

module MusicTab
	class Server < Sinatra::Base

		set :root, File.dirname(File.dirname(__FILE__))
		set :views, File.dirname(__FILE__) + "/../views"
		set :public_folder, File.dirname(__FILE__) + "/../public"
		set :bind, '0.0.0.0'
		#set :server, :thin
		
		configure :development do  
			DataMapper.auto_upgrade!  
		end 

		get '/' do
			if Sources.all.size > 0 then
				if Files.all.size == 0 then redirect '/setup/files' end
				haml :home, {:layout => :"home-layout"}
			elsif request.ip == "127.0.0.1" then
				redirect '/setup/sources'
			else
				redirect '/nothing-here'
			end				
		end 
		
		get '/setup/sources' do
			if Sources.all.size > 0 then
				redirect '/setup/files'
			else
				Dir.chdir
				@list=FOps.ls(Dir.home).to_json
				haml :setup, {:layout => :"nosetup-layout"}
			end
		end
		
		get '/setup/files' do
			Files.destroy
			Sources.each do |s|
				MusicTab::FOps.gen_list(s.path) do |arr_f|
					@files=Files.create(
						:file_path => arr_f[0],
						:title => arr_f[1],
						:album => arr_f[2],
						:artist => arr_f[3] 
					)
					#p @files.errors if @files.errors.length > 0 
					#puts arr_f[0]
				end
			end
			puts "setup complete"
			"200"
		end
		
		get '/nothing-here' do
			haml :nosetup, {:layout => :"nosetup-layout"}
		end
				
		get '/music/:id' do
			send_file(Files.get(params[:id].to_i).file_path)
		end
		
		get '/cdls/*' do
			if params[:captures].join == "BACKSPACE" then
				Dir.chdir("..")
			else
				Dir.chdir(params[:captures].join)
			end
			#puts Dir.pwd
			FOps.ls(Dir.pwd).to_json
		end
		
		get '/cwd' do
			Dir.pwd
		end
		
		post '/save/sources' do
			Sources.destroy
			sources=JSON.load(request.body.read)
			sources.each{|j|
				@source=Sources.create(
					:id => j[0],
					:path => j[1],
					:name => j[2]
				)
			}
			"1"
		end
		
	end
end
