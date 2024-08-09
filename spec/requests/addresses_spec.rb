require 'swagger_helper'

RSpec.describe 'Addresses API', type: :request do
  path '/addresses' do
    get('list addresses') do
      tags 'Addresses'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            addresses: {
              type: :array,
              items: {
                '$ref' => '#/definitions/address'
              }
            },
            pagination: {
              '$ref' => '#/definitions/page'
            }
          },
          required: %w[addresses pagination]

        run_test!
      end
    end

    post('create address') do
      tags 'Addresses'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :address, in: :body, schema: {
        type: :object,
        properties: {
          address: {
            street: { type: :string },
            city: { type: :string },
            state: { type: :string },
            zip: { type: :string }
          }
        },
        required: %w[street city state zip]
      }

      response(201, 'created') do
        let(:address) { { street: '123 Main St', city: 'Anytown', state: 'CA', zip: '12345' } }
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 street: { type: :string },
                 city: { type: :string },
                 state: { type: :string },
                 zip: { type: :string }
               },
               required: %w[id street city state zip]

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:address) { { street: '', city: '', state: '', zip: '' } }
        schema type: :object,
               properties: {
                 street: { type: :string, example: "can't be blank" },
                 city: { type: :string, example: "can't be blank" },
                 state: { type: :string, example: "can't be blank" },
                 zip: { type: :string, example: "can't be blank" }
               },
               required: %w[]

        run_test!
      end
    end
  end

  path '/addresses/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'ID of the address'

    get('show address') do
      tags 'Addresses'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 street: { type: :string },
                 city: { type: :string },
                 state: { type: :string },
                 zip: { type: :string }
               },
               required: %w[id street city state zip]

        let(:id) { Address.create(street: '123 Main St', city: 'Anytown', state: 'CA', zip: '12345').id }
        run_test!
      end

      response(404, 'not found') do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Address not found' }
               },
               required: %w[error]

        let(:id) { 'invalid' }
        run_test!
      end
    end

    patch('update address') do
      tags 'Addresses'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :address, in: :body, schema: {
        type: :object,
        properties: {
          address: {
            street: { type: :string },
            city: { type: :string },
            state: { type: :string },
            zip: { type: :string }
          }
        }
      }

      response(200, 'successful') do
        let(:id) { Address.create(street: '123 Main St', city: 'Anytown', state: 'CA', zip: '12345').id }
        let(:address) { { street: '456 Elm St' } }
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 street: { type: :string },
                 city: { type: :string },
                 state: { type: :string },
                 zip: { type: :string }
               },
               required: %w[id street city state zip]

        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        let(:address) { { street: '456 Elm St' } }
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Address not found' }
               },
               required: %w[error]

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:address) { { street: '' } }
        schema type: :object,
               properties: {
                 street: { type: :string, example: "can't be blank" },
               },
               required: %w[]

        run_test!
      end
    end

    delete('delete address') do
      tags 'Addresses'
      produces 'application/json'

      response(204, 'no content') do
        let(:id) { Address.create(street: '123 Main St', city: 'Anytown', state: 'CA', zip: '12345').id }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
