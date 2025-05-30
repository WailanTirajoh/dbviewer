namespace :db do
  namespace :secondary do
    desc 'Run migrations for the secondary database'
    task :migrate => :environment do
      ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration["secondary"])
      ActiveRecord::MigrationContext.new("db/secondary_migrate/", ActiveRecord::SchemaMigration).migrate
      
      # Generate a schema.rb file specifically for the secondary database
      schema_path = Rails.root.join("db", "secondary_schema.rb")
      File.open(schema_path, "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
      
      puts "Secondary database migrated and schema dumped to #{schema_path}"
    end
    
    desc 'Seed the secondary database'
    task :seed => :environment do
      # Add seed data for the secondary database
      SecondaryUser.create!(
        username: 'admin',
        email: 'admin@example.com',
        password_digest: 'password_digest',
        admin: true,
        api_token: SecureRandom.hex(20),
        status: 'active'
      )
      
      SecondaryUser.create!(
        username: 'john_doe',
        email: 'john@example.com',
        password_digest: 'password_digest',
        api_token: SecureRandom.hex(20),
        status: 'active'
      )
      
      user = SecondaryUser.first
      
      5.times do |i|
        blog_post = SecondaryBlogPost.create!(
          title: "Blog Post #{i + 1}",
          content: "This is the content of blog post #{i + 1}. It contains some text that will be displayed in the blog post.",
          user: user,
          slug: "blog-post-#{i + 1}",
          status: i < 3 ? 'published' : 'draft',
          published_at: i < 3 ? Time.now : nil
        )
        
        3.times do |j|
          comment = SecondaryComment.create!(
            content: "This is comment #{j + 1} on blog post #{i + 1}",
            blog_post: blog_post,
            user: SecondaryUser.all.sample,
            approved: [true, false].sample
          )
          
          # Add some replies to comments
          if j == 0
            2.times do |k|
              SecondaryComment.create!(
                content: "This is a reply #{k + 1} to comment #{j + 1}",
                blog_post: blog_post,
                user: SecondaryUser.all.sample,
                parent: comment,
                approved: true
              )
            end
          end
        end
      end
      
      puts "Secondary database seeded with sample data"
    end
    
    desc 'Reset the secondary database'
    task :reset => :environment do
      Rake::Task["db:secondary:migrate"].invoke
      Rake::Task["db:secondary:seed"].invoke
    end
  end
end
