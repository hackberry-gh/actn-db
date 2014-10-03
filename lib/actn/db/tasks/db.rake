require 'actn/db'

namespace :db do

  desc "erases and rewinds all dbs"
  task :reset do
    Rake::Task["db:drop"].execute 
    Rake::Task["db:create"].execute 
    Rake::Task["db:migrate"].execute 
  end
  
  desc "migrate your database"
  task :migrate do
    
    puts "Db Migrating... #{db_config[:dbname]}"        
    pg = PG::EM::Client.new(db_config)
    

          
    Actn::DB.paths.uniq.each do |path|
      
      puts path

      pg.exec(File.read("#{path}/db/__setup.sql")) if File.exists?("#{path}/db/__setup.sql")

      if File.exists?("#{path}/db/lib")
       `coffee --compile --output #{path}/db/lib #{path}/db/lib` rescue nil        
       
        Dir.glob("#{path}/db/lib/*.js").each do |js|
          name = File.basename(js,".js").split("_").last
          sql = "INSERT INTO plv8_modules values ($1,true,$2)"
          pg.exec_params(sql,[name,File.read(js)])
        end  
      end
      
      pg.exec(File.read("#{path}/db/__functions.sql")) if File.exists?("#{path}/db/__functions.sql")      
      
      if File.exists?("#{path}/db/")
        Dir.glob("#{path}/db/*.sql").each do |sql|
          unless File.basename(sql,".sql").start_with? "__"
            puts sql
            pg.exec(File.read(sql)) 
          end
        end   
      end
      
      if File.exists?("#{path}/db/schemas")
        Dir.glob("#{path}/db/schemas/*.json").each do |json|
          name = File.basename(json,".json").capitalize
          schema = {schema: Oj.load(File.read(json))}
          
          sql = "UPDATE core.models SET data = __patch(data,$1,true) WHERE __string(data,'name'::text) = $2 RETURNING id;"
          updated = pg.exec_params(sql,[ Oj.dump(schema), name ]).values.flatten(1).first.to_i
          
          if updated == 0
            sql = "INSERT INTO core.models (data) values (__patch(__defaults(),$1,true)) RETURNING id;"
            inserted = pg.exec_params(sql, [Oj.dump(schema.merge(name: name, table_schema: "core"))]).values.flatten(1).first.to_i
          end
          
          puts "#{name} inserted:#{inserted} updated:#{updated}"  
        end   
        
        pg.exec "SELECT plv8_startup();"
        
      end
      
      
    end    

  end

  desc 'Drops the database'
  task :drop  do
    puts "Db Dropping... #{db_config[:dbname]}"        
    pg = PG::EM::Client.new(pg_config)
    sql = "DROP DATABASE IF EXISTS \"%s\";" % [db_config[:dbname]]
    pg.exec(sql).error_message
  end

  desc 'Creates the database'
  task :create do         
    puts "Db Creating... #{db_config[:dbname]}"            
    pg = PG::EM::Client.new(pg_config)
    sql = "CREATE DATABASE \"%s\" ENCODING = 'utf8';" % [db_config[:dbname]]
    pg.exec(sql)
  end
  
  def db_config
    @db_config ||= Actn::DB.db_config.dup.tap{|s| s.delete(:size) }
  end
  
  def pg_config
    @pg_config ||= db_config.dup.merge({'dbname' => 'postgres'})
  end

end
