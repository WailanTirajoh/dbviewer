# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_25_071020) do
  create_table "addresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.string "address_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "user_id" ], name: "index_addresses_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category_id"
    t.index [ "category_id" ], name: "index_articles_on_category_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "shopping_cart_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "product_id" ], name: "index_cart_items_on_product_id"
    t.index [ "shopping_cart_id" ], name: "index_cart_items_on_shopping_cart_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "website"
    t.string "phone"
    t.string "email"
    t.date "founded_date"
    t.integer "employee_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "coupons", force: :cascade do |t|
    t.string "code"
    t.string "discount_type"
    t.decimal "discount_value"
    t.decimal "min_order_amount"
    t.integer "max_uses"
    t.integer "uses_count"
    t.date "valid_from"
    t.date "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "code" ], name: "index_coupons_on_code", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name"
    t.text "description"
    t.decimal "budget"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "company_id" ], name: "index_departments_on_company_id"
  end

  create_table "employee_skills", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "skill_id", null: false
    t.integer "proficiency_level"
    t.integer "years_experience"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "employee_id" ], name: "index_employee_skills_on_employee_id"
    t.index [ "skill_id" ], name: "index_employee_skills_on_skill_id"
  end

  create_table "employees", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "department_id", null: false
    t.integer "position_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.date "hire_date"
    t.decimal "salary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "company_id" ], name: "index_employees_on_company_id"
    t.index [ "department_id" ], name: "index_employees_on_department_id"
    t.index [ "email" ], name: "index_employees_on_email", unique: true
    t.index [ "position_id" ], name: "index_employees_on_position_id"
  end

  create_table "offices", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name"
    t.text "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "postal_code"
    t.string "phone"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "company_id" ], name: "index_offices_on_company_id"
  end

  create_table "order_coupons", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "coupon_id", null: false
    t.decimal "discount_applied"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "coupon_id" ], name: "index_order_coupons_on_coupon_id"
    t.index [ "order_id" ], name: "index_order_coupons_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "total_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "order_id" ], name: "index_order_items_on_order_id"
    t.index [ "product_id" ], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.datetime "order_date", null: false
    t.integer "shipping_address_id"
    t.integer "billing_address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "billing_address_id" ], name: "index_orders_on_billing_address_id"
    t.index [ "shipping_address_id" ], name: "index_orders_on_shipping_address_id"
    t.index [ "status" ], name: "index_orders_on_status"
    t.index [ "user_id" ], name: "index_orders_on_user_id"
  end

  create_table "positions", force: :cascade do |t|
    t.integer "department_id", null: false
    t.string "title"
    t.text "description"
    t.decimal "min_salary"
    t.decimal "max_salary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "department_id" ], name: "index_positions_on_department_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "parent_id" ], name: "index_product_categories_on_parent_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.string "sku"
    t.integer "stock_quantity"
    t.integer "product_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "product_category_id" ], name: "index_products_on_product_category_id"
    t.index [ "sku" ], name: "index_products_on_sku", unique: true
  end

  create_table "project_assignments", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "project_id", null: false
    t.string "role"
    t.date "assigned_date"
    t.decimal "hours_per_week"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "employee_id" ], name: "index_project_assignments_on_employee_id"
    t.index [ "project_id" ], name: "index_project_assignments_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name"
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.decimal "budget"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "company_id" ], name: "index_projects_on_company_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "product_id", null: false
    t.integer "rating"
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "product_id" ], name: "index_reviews_on_product_id"
    t.index [ "user_id" ], name: "index_reviews_on_user_id"
  end

  create_table "shopping_carts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "user_id" ], name: "index_shopping_carts_on_user_id"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.date "date_of_birth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_users_on_email", unique: true
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "articles", "categories"
  add_foreign_key "cart_items", "products"
  add_foreign_key "cart_items", "shopping_carts"
  add_foreign_key "departments", "companies"
  add_foreign_key "employee_skills", "employees"
  add_foreign_key "employee_skills", "skills"
  add_foreign_key "employees", "companies"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "positions"
  add_foreign_key "offices", "companies"
  add_foreign_key "order_coupons", "coupons"
  add_foreign_key "order_coupons", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "addresses", column: "billing_address_id"
  add_foreign_key "orders", "addresses", column: "shipping_address_id"
  add_foreign_key "orders", "users"
  add_foreign_key "positions", "departments"
  add_foreign_key "product_categories", "product_categories", column: "parent_id"
  add_foreign_key "products", "product_categories"
  add_foreign_key "project_assignments", "employees"
  add_foreign_key "project_assignments", "projects"
  add_foreign_key "projects", "companies"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "shopping_carts", "users"
end
