# This file is auto-generated from the current state of the secondary database.

ActiveRecord::Schema[8.0].define(version: 20250530103020) do
  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.integer "user_id", null: false
    t.string "slug"
    t.string "status", default: "draft"
    t.integer "view_count", default: 0
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "published_at" ], name: "index_blog_posts_on_published_at"
    t.index [ "slug" ], name: "index_blog_posts_on_slug", unique: true
    t.index [ "status" ], name: "index_blog_posts_on_status"
    t.index [ "user_id" ], name: "index_blog_posts_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.integer "blog_post_id", null: false
    t.integer "user_id", null: false
    t.boolean "approved", default: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "approved" ], name: "index_comments_on_approved"
    t.index [ "blog_post_id" ], name: "index_comments_on_blog_post_id"
    t.index [ "parent_id" ], name: "index_comments_on_parent_id"
    t.index [ "user_id" ], name: "index_comments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.boolean "admin", default: false
    t.string "api_token"
    t.string "status", default: "active"
    t.date "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "api_token" ], name: "index_users_on_api_token", unique: true
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "username" ], name: "index_users_on_username", unique: true
  end

  add_foreign_key "blog_posts", "users"
  add_foreign_key "comments", "blog_posts"
  add_foreign_key "comments", "users"
end
