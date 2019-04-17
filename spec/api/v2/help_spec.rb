require 'swagger_helper'

describe 'Help V2 API', swagger_doc: 'v2/swagger.json' do
  path '/help.html' do
    get 'Sends a static HTML containing help documentation' do
      tags 'help'
      produces 'text/html'

      response '200', 'HTML received' do
        let(:Accept) { 'text/html' }

        run_test!
      end
    end
  end
end
