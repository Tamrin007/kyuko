# encoding: utf-8
#require "active_record"
#require './model.rb'
require "mysql"

=begin
class Kyuko < ActiveRecord::Base
end
=end


class Extraction
	def extract_time(line)
		time = line.split('I, [')[1].split('T')[0]
	end

	def extract_kyuko(line)
		@kyuko = {}
		@kyuko[:when] = line.split('限目')[0]
		@kyuko[:name] = line.split(':')[1].split(' ')[0]
		@kyuko[:instructor] = line.split('講師(')[1].split(')')[0]
		@kyuko
	end

	def get_tanabe
		@tanabe
	end

	def get_imade
		@imade
	end

	def extract_line(file)
		# 0 = その日の情報とれていない,  1 = 田辺を取りたい,
		# 2 = 今出川を取りたい, 3 = その日の情報もうとった
		status = 0
		@imade = []
		@tanabe = []
		time = ''

		file.each_line do |line|
			if line.include?('I, [')
				time = extract_time(line)
				status = 0
				next
			end

			if line.include?('田辺') && status.zero?
				status = 1
				next
			elsif line.include?('今出川') && status == 1
				# 田辺は取り終えた
				status = 2
				next
			elsif line.include?('end') && status == 2
				stauts = 3
				next
			end

			if line.include?('限目') && status == 1
				tmp = extract_kyuko(line)
				tmp[:date] = time
				@tanabe << tmp
			elsif line.include?('限目') && status == 2
				tmp = extract_kyuko(line)
				tmp[:date] = time
				@imade << tmp
			end
		end
	end

	def extract_file(file)
		File.open(file) do |line|
			extract_line(line)
		end
	end

end

	
@client = Mysql.connect('localhost', 'root', password, 'kyuko')
data = Extraction.new
data.extract_file('./tmp/clockworkd.tweet.output')
data_imade = data.get_imade
data_imade.each do |data|
  stmt = @client.prepare("insert into kyuko_data (period, class_name, instructor, day, place) values(?, ?, ? ,?)")
  stmt.execute data[:when], data[:name], data[:instructor], data[:date], 2
=begin
	kyuko = Kyuko.new
	kyuko.when = data[:when]
	kyuko.name = data[:name]
	kyuko.instructor = data[:instructor]
	kyuko.date = data[:date]
	kyuko.save
=end
end

data_tanabe = data.get_tanabe
data_tanabe.each do |data|
  stmt = @client.prepare("insert into kyuko_data (period, class_name, instructor, day, place) values(?, ?, ? ,?)")
  stmt.execute data[:when], data[:name], data[:instructor], data[:date], 1
=begin
	kyuko = Kyuko.new
	kyuko.when = data[:when]
	kyuko.name = data[:name]
	kyuko.instructor = data[:instructor]
	kyuko.date = data[:date]
	kyuko.save
=end
end










