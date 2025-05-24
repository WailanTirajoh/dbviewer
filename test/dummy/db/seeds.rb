# Create categories
tech_cat = Category.create!(name: "Technology", description: "Technology articles and tutorials")
science_cat = Category.create!(name: "Science", description: "Science research and discoveries")
business_cat = Category.create!(name: "Business", description: "Business insights and strategies")

# Create articles with category relationships
Article.create!(
  title: "Ruby on Rails Tutorial",
  text: "Learn how to build web applications with Ruby on Rails",
  category: tech_cat
)

Article.create!(
  title: "JavaScript Fundamentals",
  text: "Understanding the basics of JavaScript programming",
  category: tech_cat
)

Article.create!(
  title: "React Components Guide",
  text: "Building reusable components in React",
  category: tech_cat
)

Article.create!(
  title: "Physics Explained",
  text: "Basic principles of physics and their applications",
  category: science_cat
)

Article.create!(
  title: "Climate Change Research",
  text: "Latest findings in climate science",
  category: science_cat
)

Article.create!(
  title: "Startup Strategies",
  text: "Effective strategies for building successful startups",
  category: business_cat
)

# Create some articles without categories to test null relationships
Article.create!(
  title: "Uncategorized Article",
  text: "This article has no category assigned",
  category: nil
)

puts "Created #{Category.count} categories and #{Article.count} articles"
puts "Articles with categories: #{Article.where.not(category_id: nil).count}"
puts "Articles without categories: #{Article.where(category_id: nil).count}"
