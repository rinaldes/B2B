ll = LevelLimit.first
unless ll
  puts "Create Default Level Limit"
  puts "======================================"

  level_limits = LevelLimit.connection.insert(
  	"INSERT INTO level_limits(level_type, limit_date, description, created_at, updated_at) VALUES
  	 ('#{GRN}', 0, 'Limit date #{GRN}','#{Date.today}','#{Date.today}'),
  	 ('#{GRPC}', 0, 'Limit date #{GRPC}','#{Date.today}','#{Date.today}'),
     ('#{GRTN}', 0, 'Limit date #{GRTN}','#{Date.today}','#{Date.today}')"
  	)
else
	puts "do nothing"
end