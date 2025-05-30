# This seed file is idempotent and can be run multiple times without creating duplicate data

puts "Seeding database..."
puts "===================="

# Create categories (existing)
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

# Create articles with category relationships (existing)
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

# Create some articles without categories to test null relationships (existing)
Article.find_or_create_by!(title: "Uncategorized Article") do |article|
  article.text = "This article has no category assigned"
  article.category = nil
end

# ECOMMERCE DATA
puts "\n=== ECOMMERCE DATA ==="

# Create Users
puts "Creating users..."
users_data = [
  { email: "john.doe@example.com", first_name: "John", last_name: "Doe", phone: "+1-555-123-4567", date_of_birth: Date.new(1985, 3, 15) },
  { email: "jane.smith@example.com", first_name: "Jane", last_name: "Smith", phone: "+1-555-234-5678", date_of_birth: Date.new(1990, 7, 22) },
  { email: "bob.johnson@example.com", first_name: "Bob", last_name: "Johnson", phone: "+1-555-345-6789", date_of_birth: Date.new(1982, 11, 8) },
  { email: "alice.brown@example.com", first_name: "Alice", last_name: "Brown", phone: "+1-555-456-7890", date_of_birth: Date.new(1988, 5, 30) },
  { email: "charlie.wilson@example.com", first_name: "Charlie", last_name: "Wilson", phone: "+1-555-567-8901", date_of_birth: Date.new(1995, 2, 14) }
]

users = users_data.map do |user_data|
  User.find_or_create_by!(email: user_data[:email]) do |user|
    user.first_name = user_data[:first_name]
    user.last_name = user_data[:last_name]
    user.phone = user_data[:phone]
    user.date_of_birth = user_data[:date_of_birth]
  end
end

# Create Product Categories
puts "Creating product categories..."
electronics = ProductCategory.find_or_create_by!(name: "Electronics") do |cat|
  cat.description = "Electronic devices and gadgets"
end

smartphones = ProductCategory.find_or_create_by!(name: "Smartphones", parent: electronics) do |cat|
  cat.description = "Mobile phones and accessories"
end

laptops = ProductCategory.find_or_create_by!(name: "Laptops", parent: electronics) do |cat|
  cat.description = "Portable computers and accessories"
end

clothing = ProductCategory.find_or_create_by!(name: "Clothing") do |cat|
  cat.description = "Fashion and apparel"
end

mens_clothing = ProductCategory.find_or_create_by!(name: "Men's Clothing", parent: clothing) do |cat|
  cat.description = "Clothing for men"
end

womens_clothing = ProductCategory.find_or_create_by!(name: "Women's Clothing", parent: clothing) do |cat|
  cat.description = "Clothing for women"
end

# Create Products
puts "Creating products..."
products_data = [
  { name: "iPhone 15 Pro", description: "Latest Apple smartphone with advanced features", price: 999.99, sku: "APPLE-IP15-PRO", stock_quantity: 50, category: smartphones },
  { name: "Samsung Galaxy S24", description: "Premium Android smartphone", price: 899.99, sku: "SAMSUNG-GS24", stock_quantity: 75, category: smartphones },
  { name: "MacBook Pro 14\"", description: "Professional laptop with M3 chip", price: 1999.99, sku: "APPLE-MBP14-M3", stock_quantity: 25, category: laptops },
  { name: "Dell XPS 13", description: "Ultrabook with premium design", price: 1299.99, sku: "DELL-XPS13", stock_quantity: 30, category: laptops },
  { name: "Men's Cotton T-Shirt", description: "Comfortable cotton t-shirt", price: 24.99, sku: "MENS-TSHIRT-001", stock_quantity: 200, category: mens_clothing },
  { name: "Women's Summer Dress", description: "Elegant summer dress", price: 79.99, sku: "WOMENS-DRESS-001", stock_quantity: 100, category: womens_clothing },
  { name: "Wireless Headphones", description: "Noise-cancelling wireless headphones", price: 199.99, sku: "HEADPHONES-WL001", stock_quantity: 80, category: electronics }
]

products = products_data.map do |product_data|
  Product.find_or_create_by!(sku: product_data[:sku]) do |product|
    product.name = product_data[:name]
    product.description = product_data[:description]
    product.price = product_data[:price]
    product.stock_quantity = product_data[:stock_quantity]
    product.product_category = product_data[:category]
  end
end

# Create Addresses
puts "Creating addresses..."
users.each_with_index do |user, index|
  Address.find_or_create_by!(user: user, address_type: "shipping") do |address|
    address.street_address = "#{100 + index * 10} Main St"
    address.city = [ "New York", "Los Angeles", "Chicago", "Houston", "Phoenix" ][index % 5]
    address.state = [ "NY", "CA", "IL", "TX", "AZ" ][index % 5]
    address.country = "USA"
    address.postal_code = "#{10000 + index * 1000}"
  end

  Address.find_or_create_by!(user: user, address_type: "billing") do |address|
    address.street_address = "#{200 + index * 10} Oak Ave"
    address.city = [ "Boston", "Seattle", "Denver", "Miami", "Portland" ][index % 5]
    address.state = [ "MA", "WA", "CO", "FL", "OR" ][index % 5]
    address.country = "USA"
    address.postal_code = "#{20000 + index * 1000}"
  end
end

# Create Orders and Order Items
puts "Creating orders..."
users.first(3).each_with_index do |user, index|
  shipping_address = user.addresses.find_by(address_type: "shipping")
  billing_address = user.addresses.find_by(address_type: "billing")

  order = Order.find_or_create_by!(
    user: user,
    order_date: Date.current - (index + 1).weeks
  ) do |o|
    o.status = [ "pending", "processing", "shipped" ][index]
    o.total_amount = 10_000
    o.shipping_address = shipping_address
    o.billing_address = billing_address
  end

  # Add order items
  selected_products = products.sample(2 + index)
  total = 0

  selected_products.each do |product|
    quantity = rand(1..3)
    unit_price = product.price
    total_price = quantity * unit_price
    total += total_price

    OrderItem.find_or_create_by!(order: order, product: product) do |item|
      item.quantity = quantity
      item.unit_price = unit_price
      item.total_price = total_price
    end
  end

  order.update!(total_amount: total)
end

# Create Reviews
puts "Creating reviews..."
review_data = [
  { user: users[0], product: products[0], rating: 5, title: "Excellent phone!", content: "Best smartphone I've ever owned. Great camera and battery life." },
  { user: users[1], product: products[0], rating: 4, title: "Good but expensive", content: "Great features but quite pricey. Overall satisfied with the purchase." },
  { user: users[2], product: products[2], rating: 5, title: "Perfect for work", content: "Amazing laptop for development work. Fast and reliable." },
  { user: users[0], product: products[4], rating: 3, title: "Average quality", content: "Decent t-shirt but fabric could be better for the price." }
]

review_data.each do |review_info|
  Review.find_or_create_by!(
    user: review_info[:user],
    product: review_info[:product]
  ) do |review|
    review.rating = review_info[:rating]
    review.title = review_info[:title]
    review.content = review_info[:content]
  end
end

# COMPANY PROFILE DATA
puts "\n=== COMPANY PROFILE DATA ==="

# Create Companies
puts "Creating companies..."
companies_data = [
  { name: "TechCorp Inc.", description: "Leading technology solutions provider", website: "https://techcorp.com", phone: "+1-555-TECH-001", email: "info@techcorp.com", founded_date: Date.new(2010, 1, 15), employee_count: 250 },
  { name: "InnovateLabs", description: "Research and development company", website: "https://innovatelabs.com", phone: "+1-555-INNO-002", email: "contact@innovatelabs.com", founded_date: Date.new(2015, 6, 30), employee_count: 120 },
  { name: "DataSystems Ltd.", description: "Big data and analytics solutions", website: "https://datasystems.com", phone: "+1-555-DATA-003", email: "hello@datasystems.com", founded_date: Date.new(2008, 9, 10), employee_count: 180 }
]

companies = companies_data.map do |company_data|
  Company.find_or_create_by!(name: company_data[:name]) do |company|
    company.description = company_data[:description]
    company.website = company_data[:website]
    company.phone = company_data[:phone]
    company.email = company_data[:email]
    company.founded_date = company_data[:founded_date]
    company.employee_count = company_data[:employee_count]
  end
end

# Create Departments
puts "Creating departments..."
departments_data = [
  { company: companies[0], name: "Engineering", description: "Software development and technical operations", budget: 2000000 },
  { company: companies[0], name: "Marketing", description: "Brand and product marketing", budget: 800000 },
  { company: companies[0], name: "Human Resources", description: "People operations and talent management", budget: 500000 },
  { company: companies[1], name: "Research", description: "Core research and development", budget: 1500000 },
  { company: companies[1], name: "Product", description: "Product management and strategy", budget: 700000 },
  { company: companies[2], name: "Data Science", description: "Analytics and machine learning", budget: 1200000 },
  { company: companies[2], name: "Sales", description: "Business development and client relations", budget: 600000 }
]

departments = departments_data.map do |dept_data|
  Department.find_or_create_by!(company: dept_data[:company], name: dept_data[:name]) do |dept|
    dept.description = dept_data[:description]
    dept.budget = dept_data[:budget]
  end
end

# Create Positions
puts "Creating positions..."
positions_data = [
  { department: departments[0], title: "Senior Software Engineer", description: "Lead development of core applications", min_salary: 120000, max_salary: 180000 },
  { department: departments[0], title: "DevOps Engineer", description: "Infrastructure and deployment automation", min_salary: 110000, max_salary: 160000 },
  { department: departments[1], title: "Marketing Manager", description: "Lead marketing campaigns and strategy", min_salary: 90000, max_salary: 130000 },
  { department: departments[2], title: "HR Specialist", description: "Talent acquisition and employee relations", min_salary: 70000, max_salary: 100000 },
  { department: departments[3], title: "Research Scientist", description: "Conduct advanced research projects", min_salary: 130000, max_salary: 200000 },
  { department: departments[4], title: "Product Manager", description: "Drive product strategy and roadmap", min_salary: 100000, max_salary: 150000 },
  { department: departments[5], title: "Data Scientist", description: "Analyze data and build ML models", min_salary: 115000, max_salary: 170000 },
  { department: departments[6], title: "Sales Director", description: "Lead sales team and strategy", min_salary: 140000, max_salary: 220000 }
]

positions = positions_data.map do |pos_data|
  Position.find_or_create_by!(department: pos_data[:department], title: pos_data[:title]) do |pos|
    pos.description = pos_data[:description]
    pos.min_salary = pos_data[:min_salary]
    pos.max_salary = pos_data[:max_salary]
  end
end

# Create Employees
puts "Creating employees..."
employees_data = [
  { company: companies[0], department: departments[0], position: positions[0], first_name: "Sarah", last_name: "Connor", email: "sarah.connor@techcorp.com", phone: "+1-555-001-0001", hire_date: Date.new(2020, 3, 15), salary: 150000 },
  { company: companies[0], department: departments[0], position: positions[1], first_name: "Mike", last_name: "Johnson", email: "mike.johnson@techcorp.com", phone: "+1-555-001-0002", hire_date: Date.new(2021, 7, 20), salary: 140000 },
  { company: companies[0], department: departments[1], position: positions[2], first_name: "Emily", last_name: "Davis", email: "emily.davis@techcorp.com", phone: "+1-555-001-0003", hire_date: Date.new(2019, 11, 5), salary: 110000 },
  { company: companies[0], department: departments[2], position: positions[3], first_name: "David", last_name: "Wilson", email: "david.wilson@techcorp.com", phone: "+1-555-001-0004", hire_date: Date.new(2022, 2, 10), salary: 85000 },
  { company: companies[1], department: departments[3], position: positions[4], first_name: "Dr. Lisa", last_name: "Chen", email: "lisa.chen@innovatelabs.com", phone: "+1-555-002-0001", hire_date: Date.new(2018, 5, 1), salary: 180000 },
  { company: companies[1], department: departments[4], position: positions[5], first_name: "James", last_name: "Martinez", email: "james.martinez@innovatelabs.com", phone: "+1-555-002-0002", hire_date: Date.new(2020, 9, 15), salary: 125000 },
  { company: companies[2], department: departments[5], position: positions[6], first_name: "Anna", last_name: "Rodriguez", email: "anna.rodriguez@datasystems.com", phone: "+1-555-003-0001", hire_date: Date.new(2019, 4, 20), salary: 145000 },
  { company: companies[2], department: departments[6], position: positions[7], first_name: "Robert", last_name: "Taylor", email: "robert.taylor@datasystems.com", phone: "+1-555-003-0002", hire_date: Date.new(2017, 12, 1), salary: 190000 }
]

employees = employees_data.map do |emp_data|
  Employee.find_or_create_by!(email: emp_data[:email]) do |emp|
    emp.company = emp_data[:company]
    emp.department = emp_data[:department]
    emp.position = emp_data[:position]
    emp.first_name = emp_data[:first_name]
    emp.last_name = emp_data[:last_name]
    emp.phone = emp_data[:phone]
    emp.hire_date = emp_data[:hire_date]
    emp.salary = emp_data[:salary]
  end
end

# Create Projects
puts "Creating projects..."
projects_data = [
  { company: companies[0], name: "Mobile App Redesign", description: "Complete redesign of mobile application", start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 6, 30), budget: 500000, status: "active" },
  { company: companies[0], name: "AI Integration", description: "Integrate AI features into existing products", start_date: Date.new(2024, 3, 1), end_date: Date.new(2024, 12, 31), budget: 800000, status: "planning" },
  { company: companies[1], name: "Quantum Research", description: "Research into quantum computing applications", start_date: Date.new(2023, 6, 1), end_date: Date.new(2025, 5, 31), budget: 2000000, status: "active" },
  { company: companies[2], name: "Big Data Platform", description: "Next-generation data analytics platform", start_date: Date.new(2023, 9, 1), end_date: Date.new(2024, 8, 31), budget: 1200000, status: "active" }
]

projects = projects_data.map do |proj_data|
  Project.find_or_create_by!(company: proj_data[:company], name: proj_data[:name]) do |proj|
    proj.description = proj_data[:description]
    proj.start_date = proj_data[:start_date]
    proj.end_date = proj_data[:end_date]
    proj.budget = proj_data[:budget]
    proj.status = proj_data[:status]
  end
end

# Create Project Assignments
puts "Creating project assignments..."
assignments_data = [
  { employee: employees[0], project: projects[0], role: "lead", assigned_date: Date.new(2024, 1, 1), hours_per_week: 40 },
  { employee: employees[1], project: projects[0], role: "developer", assigned_date: Date.new(2024, 1, 15), hours_per_week: 35 },
  { employee: employees[0], project: projects[1], role: "developer", assigned_date: Date.new(2024, 3, 1), hours_per_week: 20 },
  { employee: employees[4], project: projects[2], role: "lead", assigned_date: Date.new(2023, 6, 1), hours_per_week: 40 },
  { employee: employees[6], project: projects[3], role: "lead", assigned_date: Date.new(2023, 9, 1), hours_per_week: 35 }
]

assignments_data.each do |assign_data|
  ProjectAssignment.find_or_create_by!(
    employee: assign_data[:employee],
    project: assign_data[:project]
  ) do |assignment|
    assignment.role = assign_data[:role]
    assignment.assigned_date = assign_data[:assigned_date]
    assignment.hours_per_week = assign_data[:hours_per_week]
  end
end

# Create Skills
puts "Creating skills..."
skills_data = [
  { name: "Ruby on Rails", category: "technical", description: "Web application framework" },
  { name: "JavaScript", category: "technical", description: "Programming language for web development" },
  { name: "Python", category: "technical", description: "General-purpose programming language" },
  { name: "Machine Learning", category: "technical", description: "AI and data science techniques" },
  { name: "Project Management", category: "soft", description: "Planning and executing projects" },
  { name: "Leadership", category: "leadership", description: "Leading teams and organizations" },
  { name: "Public Speaking", category: "soft", description: "Presenting to audiences" },
  { name: "Data Analysis", category: "technical", description: "Analyzing and interpreting data" },
  { name: "Marketing Strategy", category: "domain_specific", description: "Developing marketing plans" },
  { name: "Sales", category: "domain_specific", description: "Business development and client relations" }
]

skills = skills_data.map do |skill_data|
  Skill.find_or_create_by!(name: skill_data[:name]) do |skill|
    skill.category = skill_data[:category]
    skill.description = skill_data[:description]
  end
end

# Create Employee Skills
puts "Creating employee skills..."
employee_skills_data = [
  { employee: employees[0], skill: skills[0], proficiency_level: 5, years_experience: 8 },
  { employee: employees[0], skill: skills[1], proficiency_level: 4, years_experience: 6 },
  { employee: employees[0], skill: skills[4], proficiency_level: 4, years_experience: 5 },
  { employee: employees[1], skill: skills[2], proficiency_level: 5, years_experience: 7 },
  { employee: employees[1], skill: skills[3], proficiency_level: 3, years_experience: 2 },
  { employee: employees[2], skill: skills[8], proficiency_level: 5, years_experience: 10 },
  { employee: employees[2], skill: skills[6], proficiency_level: 4, years_experience: 8 },
  { employee: employees[4], skill: skills[3], proficiency_level: 5, years_experience: 12 },
  { employee: employees[4], skill: skills[7], proficiency_level: 5, years_experience: 15 },
  { employee: employees[6], skill: skills[3], proficiency_level: 4, years_experience: 5 },
  { employee: employees[6], skill: skills[7], proficiency_level: 5, years_experience: 6 },
  { employee: employees[7], skill: skills[9], proficiency_level: 5, years_experience: 12 },
  { employee: employees[7], skill: skills[5], proficiency_level: 4, years_experience: 8 }
]

employee_skills_data.each do |es_data|
  EmployeeSkill.find_or_create_by!(
    employee: es_data[:employee],
    skill: es_data[:skill]
  ) do |es|
    es.proficiency_level = es_data[:proficiency_level]
    es.years_experience = es_data[:years_experience]
  end
end

puts "\n===================="
puts "Seeding completed!"
puts "Database stats:"
puts "Created #{Category.count} categories and #{Article.count} articles"
puts "Articles with categories: #{Article.where.not(category_id: nil).count}"
puts "Articles without categories: #{Article.where(category_id: nil).count}"
puts "\nEcommerce data:"
puts "Users: #{User.count}"
puts "Product Categories: #{ProductCategory.count}"
puts "Products: #{Product.count}"
puts "Orders: #{Order.count}"
puts "Order Items: #{OrderItem.count}"
puts "Reviews: #{Review.count}"
puts "\nCompany data:"
puts "Companies: #{Company.count}"
puts "Departments: #{Department.count}"
puts "Positions: #{Position.count}"
puts "Employees: #{Employee.count}"
puts "Projects: #{Project.count}"
puts "Project Assignments: #{ProjectAssignment.count}"
puts "Skills: #{Skill.count}"
puts "Employee Skills: #{EmployeeSkill.count}"

puts "\nSetting up secondary database (Blog)..."
if defined?(SecondaryDatabase) && defined?(SecondaryUser)
  puts "Creating users for the secondary database..."

  # Only create if table is empty
  if SecondaryUser.count == 0
    users_data = [
      { username: "john_doe", email: "john@example.com", password_digest: "password123", admin: true, status: "active" },
      { username: "jane_smith", email: "jane@example.com", password_digest: "password123", status: "active" },
      { username: "bob_jones", email: "bob@example.com", password_digest: "password123", status: "inactive" }
    ]

    users = users_data.map do |user_data|
      SecondaryUser.create!(
        username: user_data[:username],
        email: user_data[:email],
        password_digest: user_data[:password_digest],
        admin: user_data[:admin] || false,
        status: user_data[:status],
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    # Create blog posts
    puts "Creating blog posts for the secondary database..."
    blog_posts_data = [
      { title: "Getting Started with Rails", content: "Ruby on Rails is a web application framework...", user: users[0], status: "published" },
      { title: "Advanced ActiveRecord Techniques", content: "ActiveRecord provides a rich API for...", user: users[1], status: "draft" },
      { title: "Building APIs with Rails", content: "In this article, we will explore...", user: users[0], status: "published" }
    ]

    blog_posts = blog_posts_data.map do |post_data|
      SecondaryBlogPost.create!(
        title: post_data[:title],
        content: post_data[:content],
        user: post_data[:user],
        status: post_data[:status],
        slug: post_data[:title].parameterize,
        published_at: post_data[:status] == "published" ? Time.current : nil,
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    # Create comments
    puts "Creating comments for the secondary database..."
    comments_data = [
      { content: "Great article!", blog_post: blog_posts[0], user: users[1], approved: true },
      { content: "I have a question about...", blog_post: blog_posts[0], user: users[2], approved: true },
      { content: "Looking forward to the next part!", blog_post: blog_posts[2], user: users[1], approved: true },
      { content: "Thanks for sharing this knowledge", blog_post: blog_posts[2], user: users[2], approved: false }
    ]

    comments_data.each do |comment_data|
      SecondaryComment.create!(
        content: comment_data[:content],
        blog_post: comment_data[:blog_post],
        user: comment_data[:user],
        approved: comment_data[:approved],
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    puts "Secondary database seed completed successfully!"
  else
    puts "Secondary database already has data, skipping seed."
  end
else
  puts "SecondaryDatabase models not defined, skipping secondary database seeding."
end
