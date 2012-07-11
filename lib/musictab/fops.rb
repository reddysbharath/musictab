require "mp3info"
module MusicTab
	module FOps
		
		def self.ls(dir)
			arr=Dir[dir+'/*']
			#filters mp3 files
			filtered_arr=[]
			arr.each{ |a|
				if !File.directory?(a) then
					filtered_arr<< File.basename(a) if IO.read(a,8) == "ID3\x03\x00\x00\x00\x00"				
				else
					filtered_arr<< File.basename(a)
				end				
			}
			return filtered_arr.sort!
		end
		
		def self.get_meta(dir)
			arr=Dir[dir+'/*']
			#filters mp3 files
			filtered_arr=[]
			arr.each{ |a|
				if !File.directory?(a) then
					yield File.basename(a) if IO.read(a,8) == "ID3\x03\x00\x00\x00\x00"				
				else
					yield File.basename(a)
				end				
			}
		end
		
		def self.gen_list(dir)
			prev_pwd=Dir.pwd
			begin
				Dir.chdir(dir)
			rescue Errno::EACCES
			end
			counter = 0
			Dir[Dir.pwd+'/*'].each{|x|
				if File.directory?(x) then
					self.gen_list(x) do |y|
						yield y
					end
				else if IO.read(x,8) == "ID3\x03\x00\x00\x00\x00" then
					begin
						Mp3Info.open(x) do |y|
							yield [x,y.tag.title,y.tag.album,y.tag.artist]
						end
					rescue Mp3InfoError
					end
				end end
			}
			Dir.chdir(prev_pwd)
		end
	end
end
