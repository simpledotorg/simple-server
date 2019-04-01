require 'swagger_helper'

describe 'Help Current API', swagger_doc: 'current/swagger.json' do
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
