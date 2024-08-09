require 'swagger_helper'

RSpec.describe 'Rides API', type: :request do
  path '/driver/{driver_id}/rides' do
    parameter name: :driver_id, in: :path, type: :integer, description: 'ID of the driver'

    get('list rides for a driver') do
      tags 'Rides'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            rides: {
              type: :array,
              items: {
                '$ref' => '#/definitions/ride'
              }
            },
            pagination: {
              '$ref' => '#/definitions/page'
            }
          },
          required: %w[rides pagination]

        let(:driver_id) { 1 }
        before do
          create(:ride, driver_id: driver_id, start_address_id: 1, dest_address_id: 2, ride_score: 10)
        end

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:driver_id) { -1 }

        run_test!
      end
    end
  end

  path '/rides/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'ID of the ride'

    get('show ride') do
      tags 'Rides'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 driver_id: { type: :integer },
                 start_address_id: { type: :integer },
                 dest_address_id: { type: :integer }
               },
               required: %w[id driver_id start_address_id dest_address_id]

        let(:id) { create(:ride).id }

        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }

        run_test!
      end
    end

    patch('update ride') do
      tags 'Rides'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :ride, in: :body, schema: {
        type: :object,
        properties: {
          ride: {
            driver_id: { type: :integer },
            start_address_id: { type: :integer },
            dest_address_id: { type: :integer }
          }
        },
        required: %w[driver_id start_address_id dest_address_id]
      }

      response(200, 'successful') do
        let(:id) { create(:ride).id }
        let(:ride) { { start_address_id: 2, dest_address_id: 3 } }

        schema '$ref' => '#/definitions/ride'

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:id) { create(:ride).id }
        let(:ride) { { start_address_id: nil, dest_address_id: nil } }

        schema type: :object,
               properties: {
                 error: { type: :string, example: "error in create ride: missing params: driver_id, start_address_id" },
               },
               required: %w[error]

        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        let(:ride) { { start_address_id: 2, dest_address_id: 3 } }

        run_test!
      end
    end

    delete('delete ride') do
      tags 'Rides'
      produces 'application/json'

      response(204, 'no content') do
        let(:id) { create(:ride).id }

        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }

        run_test!
      end
    end
  end

  path '/rides' do
    post('create ride') do
      tags 'Rides'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :ride, in: :body, schema: {
        type: :object,
        properties: {
          driver_id: { type: :integer },
          start_address_id: { type: :integer },
          dest_address_id: { type: :integer }
        },
        required: %w[driver_id start_address_id dest_address_id]
      }

      response(201, 'created') do
        let(:ride) { { driver_id: 1, start_address_id: 1, dest_address_id: 2 } }

        schema type: :object,
               properties: {
                 id: { type: :integer },
                 driver_id: { type: :integer },
                 start_address_id: { type: :integer },
                 dest_address_id: { type: :integer }
               },
               required: %w[id driver_id start_address_id dest_address_id]

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:ride) { { driver_id: nil, start_address_id: nil, dest_address_id: nil } }

        run_test!
      end
    end
  end
end
