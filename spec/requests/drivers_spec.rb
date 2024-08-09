require 'swagger_helper'

RSpec.describe 'Drivers API', type: :request do
  path '/drivers' do
    get('list drivers') do
      tags 'Drivers'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            drivers: {
              type: :array,
              items: {
                '$ref' => '#/definitions/driver'
              }
            },
            pagination: {
              '$ref' => '#/definitions/page'
            }
          },
          required: %w[drivers pagination]

        run_test!
      end
    end

    post('create driver') do
      tags 'Drivers'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :driver, in: :body, schema: {
        type: :object,
        properties: {
          driver: {
            home_address_id: { type: :integer }
          }
        },
        required: %w[home_address_id]
      }

      response(201, 'created') do
        let(:driver) { { home_address_id: 1 } }
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 home_address_id: { type: :integer },
                 created_at: { type: :string, format: :datetime },
                 updated_at: { type: :string, format: :datetime }
               },
               required: %w[id home_address_id created_at updated_at]

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:driver) { { home_address_id: nil } }
        schema type: :object,
               properties: {
                 home_address: { type: :integer, example: "must exist" },
                 home_address_id: { type: :integer, example: "can't be blank" },
               },
               required: %w[]

        run_test!
      end
    end
  end

  path '/drivers/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'ID of the driver'

    get('show driver') do
      tags 'Drivers'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 home_address_id: { type: :integer },
                 created_at: { type: :string, format: :datetime },
                 updated_at: { type: :string, format: :datetime }
               },
               required: %w[id home_address_id created_at updated_at]

        let(:id) { Driver.create(home_address_id: 1).id }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        let(:address) { { street: '456 Elm St' } }
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Driver not found' }
               },
               required: %w[error]

        run_test!
      end
    end

    patch('update driver') do
      tags 'Drivers'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :driver, in: :body, schema: {
        type: :object,
        properties: {
          driver: {
            home_address_id: { type: :integer }
          }
        }
      }

      response(200, 'successful') do
        let(:id) { Driver.create(home_address_id: 1).id }
        let(:driver) { { home_address_id: 2 } }

        schema type: :object,
               properties: {
                 id: { type: :integer },
                 home_address_id: { type: :integer },
                 created_at: { type: :string, format: :datetime },
                 updated_at: { type: :string, format: :datetime }
               },
               required: %w[id home_address_id created_at updated_at]

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:address) { { home_address_id: '' } }
        schema type: :object,
               properties: {
                 home_address: { type: :string, example: "must exist" },
                 home_address_id: { type: :string, example: "can't be blank" },
               },
               required: %w[]

        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        let(:address) { { street: '456 Elm St' } }
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Driver not found' }
               },
               required: %w[error]

        run_test!
      end
    end

    delete('delete driver') do
      tags 'Drivers'
      produces 'application/json'

      response(204, 'no content') do
        let(:id) { Driver.create(home_address_id: 1).id }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Driver not found' }
               },
               required: %w[error]

        run_test!
      end
    end
  end
end
