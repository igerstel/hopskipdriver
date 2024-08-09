# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'www.example.com'
            }
          }
        }
      ],
      definitions: {
        ride: {
          type: :object,
          properties: {
            id: { type: :integer },
            driver_id: { type: :integer },
            start_address_id: { type: :integer },
            dest_address_id: { type: :integer },
            commute_dist: { type: :number },
            commute_duration: { type: :number },
            ride_dist: { type: :number },
            ride_duration: { type: :number },
            ride_earnings: { type: :number },
            ride_score: { type: :number },
            updated_at: { type: :string },
            created_at: { type: :string }
          },
          required: %w[id driver_id start_address_id dest_address_id commute_dist commute_duration ride_dist ride_duration ride_earnings ride_score created_at updated_at]
        },
        page: {
          type: :object,
          properties: {
            page: { type: :integer },
            per_page: { type: :integer },
            count: { type: :integer },
            pages: { type: :integer }
          },
          required: %w[page per_page count pages]
        },
        address: {
          type: :object,
          properties: {
            id: { type: :integer },
            street: { type: :string },
            city: { type: :string },
            state: { type: :string },
            zip: { type: :string },
            created_at: { type: :string, format: :datetime },
            updated_at: { type: :string, format: :datetime }
          },
          required: %w[id street city state zip]
        },
        driver: {
          type: :object,
          properties: {
            id: { type: :integer },
            home_address_id: { type: :integer },
            created_at: { type: :string, format: :datetime },
            updated_at: { type: :string, format: :datetime }
          },
          required: %w[id street city state zip]
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :json
end
