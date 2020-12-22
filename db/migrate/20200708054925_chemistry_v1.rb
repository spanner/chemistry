# Optional migration to support the import and upgrading of old page data from Chemistry v1.

class ChemistryV1 < ActiveRecord::Migration[5.2]

  create_table "chemistry_documents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "file_file_name"
    t.string "file_content_type"
    t.bigint "file_file_size"
    t.datetime "file_updated_at"
    t.string "remote_url"
    t.integer "position"
    t.string "title"
    t.text "caption"
    t.text "file_meta"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chemistry_images", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "file_file_name"
    t.string "file_content_type"
    t.bigint "file_file_size"
    t.datetime "file_updated_at"
    t.string "remote_url"
    t.string "title"
    t.text "caption"
    t.integer "width"
    t.integer "height"
    t.text "file_meta"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_chemistry_images_on_user_id"
  end

  create_table "chemistry_pages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "template_id"
    t.integer "parent_id"
    t.string "path"
    t.string "slug"
    t.string "content"
    t.string "title"
    t.text "summary"
    t.text "excerpt"
    t.boolean "home", default: false
    t.boolean "nav", default: false
    t.string "nav_name"
    t.integer "nav_position"
    t.text "rendered_html", limit: 16777215
    t.string "external_url"
    t.integer "document_id"
    t.datetime "published_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "date"
    t.datetime "to_date"
    t.integer "image_id"
    t.integer "video_id"
    t.string "owner_type"
    t.integer "owner_id"
    t.text "original_context"
    t.datetime "began_at"
    t.datetime "ended_at"
    t.string "prefix"
    t.boolean "private", default: false
    t.boolean "automatic", default: false
    t.index ["deleted_at"], name: "index_chemistry_pages_on_deleted_at"
    t.index ["home"], name: "index_chemistry_pages_on_home"
    t.index ["nav"], name: "index_chemistry_pages_on_nav"
    t.index ["owner_type", "owner_id"], name: "index_chemistry_pages_on_owner_type_and_owner_id"
    t.index ["parent_id"], name: "index_chemistry_pages_on_parent_id"
    t.index ["published_at", "path"], name: "index_chemistry_pages_on_published_at_and_path"
    t.index ["template_id"], name: "index_chemistry_pages_on_template_id"
  end

  create_table "chemistry_section_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "description"
    t.text "template"
    t.string "icon_file_name"
    t.string "icon_content_type"
    t.bigint "icon_file_size"
    t.datetime "icon_updated_at"
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chemistry_sections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "page_id"
    t.integer "position"
    t.boolean "detached", default: false
    t.integer "section_type_id"
    t.string "title"
    t.text "primary_html", limit: 16777215
    t.text "secondary_html", limit: 16777215
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "background_html", limit: 16777215
    t.string "prefix"
    t.index ["deleted_at"], name: "index_chemistry_sections_on_deleted_at"
    t.index ["page_id", "position"], name: "index_chemistry_sections_on_page_id_and_position"
    t.index ["section_type_id"], name: "index_chemistry_sections_on_section_type_id"
  end

  create_table "chemistry_videos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "file_file_name"
    t.string "file_content_type"
    t.bigint "file_file_size"
    t.datetime "file_updated_at"
    t.string "remote_url"
    t.string "title"
    t.text "caption"
    t.string "provider"
    t.text "embed_code"
    t.integer "width"
    t.integer "height"
    t.integer "duration"
    t.string "thumbnail_large"
    t.string "thumbnail_medium"
    t.string "thumbnail_small"
    t.text "file_meta"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_chemistry_videos_on_user_id"
  end

end