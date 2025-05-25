# This seed file is idempotent and can be run multiple times without creating duplicate data

puts "Seeding database..."
puts "===================="

# Create categories
puts "Creating or finding categories..."
tech_cat = Category.find_or_create_by!(name: "Technology") do |category|
  category.description = "Technology articles and tutorials"
end

science_cat = Category.find_or_create_by!(name: "Science") do |category|
  category.description = "Science research and discoveries"
end

business_cat = Category.find_or_create_by!(name: "Business") do |category|
  category.description = "Business insights and strategies"
end

# Create articles with category relationships
puts "\nCreating or finding articles..."
Article.find_or_create_by!(title: "Ruby on Rails Tutorial") do |article|
  article.text = "Learn how to build web applications with Ruby on Rails"
  article.category = tech_cat
end

Article.find_or_create_by!(title: "JavaScript Fundamentals") do |article|
  article.text = "Understanding the basics of JavaScript programming"
  article.category = tech_cat
end

Article.find_or_create_by!(title: "React Components Guide") do |article|
  article.text = "Building reusable components in React"
  article.category = tech_cat
end

Article.find_or_create_by!(title: "Physics Explained") do |article|
  article.text = "Basic principles of physics and their applications"
  article.category = science_cat
end

Article.find_or_create_by!(title: "Climate Change Research") do |article|
  article.text = "Latest findings in climate science"
  article.category = science_cat
end

Article.find_or_create_by!(title: "Startup Strategies") do |article|
  article.text = "Effective strategies for building successful startups"
  article.category = business_cat
end

# Create some articles without categories to test null relationships
Article.find_or_create_by!(title: "Uncategorized Article") do |article|
  article.text = "This article has no category assigned"
  article.category = nil
end

puts "\n===================="
puts "Seeding completed!"
puts "Database stats:"
puts "Created #{Category.count} categories and #{Article.count} articles"
puts "Articles with categories: #{Article.where.not(category_id: nil).count}"
puts "Articles without categories: #{Article.where(category_id: nil).count}"
