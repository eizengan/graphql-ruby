# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/input_generator"

class GraphQLGeneratorsInputGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::InputGenerator

  ActiveRecord::Schema.define do
    self.verbose = !!ENV["GITHUB_ACTIONS"]
    create_table :input_test_users, force: true do |t|
      t.datetime :created_at
      t.date :birthday
      t.integer :points
      t.decimal :rating
      t.references :friend, foreign_key: { to_table: :input_test_users}
    end
  end

  # rubocop:disable Style/ClassAndModuleChildren
  class ::InputTestUser < ActiveRecord::Base
  end
  # rubocop:enable Style/ClassAndModuleChildren

  test "it generates arguments with types" do
    commands = [
      # GraphQL-style:
      ["Bird", "wingspan:Int!", "foliage:[Color]"],
      # Ruby-style:
      ["BirdType", "wingspan:!Integer", "foliage:[Types::ColorType]"],
      # Mixed
      ["BirdType", "wingspan:!Int", "foliage:[Color]"],
    ]

    expected_content = <<-RUBY
# frozen_string_literal: true

module Types
  class BirdInputType < Types::BaseInputObject
    argument :wingspan, Integer, required: false
    argument :foliage, [Types::ColorType], required: false
  end
end
RUBY

    commands.each do |c|
      prepare_destination
      run_generator(c)
      assert_file "app/graphql/types/bird_input_type.rb", expected_content
    end
  end

  test "it generates classified file" do
    run_generator(["page"])
    assert_file "app/graphql/types/page_input_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class PageInputType < Types::BaseInputObject
  end
end
RUBY
  end

  test "it generates namespaced classified file" do
    run_generator(["page", "--namespaced-types"])
    assert_file "app/graphql/types/inputs/page_input_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class Inputs::PageInputType < Types::BaseInputObject
  end
end
RUBY
  end

  test "it generates objects based on ActiveRecord schema" do
    run_generator(["InputTestUser"])
    assert_file "app/graphql/types/input_test_user_input_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class InputTestUserInputType < Types::BaseInputObject
    argument :id, ID, required: false
    argument :created_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :birthday, GraphQL::Types::ISO8601Date, required: false
    argument :points, Integer, required: false
    argument :rating, Float, required: false
    argument :friend_id, Integer, required: false
  end
end
RUBY
  end


  test "it generates namespaced objects based on ActiveRecord schema" do
    run_generator(["InputTestUser", "--namespaced-types"])
    assert_file "app/graphql/types/inputs/input_test_user_input_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class Inputs::InputTestUserInputType < Types::BaseInputObject
    argument :id, ID, required: false
    argument :created_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :birthday, GraphQL::Types::ISO8601Date, required: false
    argument :points, Integer, required: false
    argument :rating, Float, required: false
    argument :friend_id, Integer, required: false
  end
end
RUBY
  end


  test "it generates objects based on ActiveRecord schema with additional custom arguments" do
    run_generator(["InputTestUser", "name:!String", "email:!Citext", "settings:jsonb"])
    assert_file "app/graphql/types/input_test_user_input_type.rb", <<-RUBY
# frozen_string_literal: true

module Types
  class InputTestUserInputType < Types::BaseInputObject
    argument :id, ID, required: false
    argument :created_at, GraphQL::Types::ISO8601DateTime, required: false
    argument :birthday, GraphQL::Types::ISO8601Date, required: false
    argument :points, Integer, required: false
    argument :rating, Float, required: false
    argument :friend_id, Integer, required: false
    argument :name, String, required: false
    argument :email, String, required: false
    argument :settings, GraphQL::Types::JSON, required: false
  end
end
RUBY
  end
end
