module DceLti
  describe ConfigsController do
    include ConfigurationHelpers

    routes { DceLti::Engine.routes }

    context '#index' do
      it 'uses IMS::LTI::ToolConfig to construct the tool config' do
        configurer_double = create_configurer_double

        get :index, { format: :xml }

        expect(configurer_double).to have_received(:to_xml)
      end

      it 'renders XML' do
        create_configurer_double

        get :index, {format: :xml }

        expect(response.content_type).to eq 'application/xml'
      end

      it 'defaults launch_url to sessions_url' do
        sessions_url = 'foobar'
        allow(controller).to receive(:sessions_url).and_return(sessions_url)
        create_configurer_double

        get :index, {format: :xml }

        expect(IMS::LTI::ToolConfig).to have_received(:new).with(
          hash_including(launch_url: sessions_url)
        )
        expect(controller).to have_received(:sessions_url)
      end

      it 'evaluates custom lambdas with controller context correctly' do
        allow(controller).to receive(:awesome_method)

        tool_config_extensions = ->(controller, tool_config) {
          tool_config.extend ::IMS::LTI::Extensions::Canvas::ToolConfig
          tool_config.canvas_domain!(controller.awesome_method)
        }
        with_overridden_lti_config_of({tool_config_extensions: tool_config_extensions}) do
          get :index, { format: :xml}
          expect(controller).to have_received(:awesome_method)
        end
      end

      it 'passes in the correct variables' do
        with_overridden_lti_config_of({}) do |lti_config|
          create_configurer_double
          get :index, { format: :xml}

          expect(IMS::LTI::ToolConfig).to have_received(:new).with(
            hash_including(
              title: lti_config.provider_title,
              description: lti_config.provider_description,
            )
          )
        end
      end
    end

    def create_configurer_double
      double(
        'IMS::LTI::ToolConfig',
        to_xml: '<xml></xml>',
        set_ext_param: '',
      ).tap do |configurer_double|
        allow(IMS::LTI::ToolConfig).to receive(:new).and_return(configurer_double)
      end
    end
  end
end
