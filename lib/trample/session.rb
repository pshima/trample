module Trample
  class Session
    include Logging
    include Timer
    
    attr_reader :id, :config, :response_times, :cookies, :last_response

    HTTP_ACCEPT_HEADER = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

    def initialize(config, instance_number)
      @id = instance_number
      @config         = config
      @cookies        = {}
    end

    def trample
      time do
        hit @config.login unless @config.login.nil?
        @config.iterations.times do
          iteration_time = time do
            @config.pages.each do |p|
              if p.think_time and p.think_time > 0
                logger.info "Thinking for #{p.think_time}"
                sleep(p.think_time)
              end
              hit p
            end
          end
          logger.info "ITERATION #{@id} #{iteration_time}"
        end
      end
    end

    protected
      def hit(page)
        response_time = request(page)
        # this is ugly, but it's the only way that I could get the test to pass
        # because rr keeps a reference to the arguments, not a copy. ah well.
        @cookies = cookies.merge(last_response.cookies)
        logger.info "#{page.request_method.to_s.upcase} #{page.url} #{response_time}s #{last_response.code}"
      end

      def request(page)
        time do
          url = String.new(page.url)
          params = page.parameters
          @last_response = send(page.request_method, url, params)
          if @config.response_processor
            @config.response_processor.call(@session_id, url, @last_response)
          end
        end
      end

      def get(url, params)
        if @config.request_filter
          @config.request_filter.call(@session_id, :get, url, params)
        end
        RestClient.get(url, :cookies => cookies, :accept => HTTP_ACCEPT_HEADER)
      end

      def post(url, params)
        if @config.request_filter
          @config.request_filter.call(@session_id, :post, url, params)
        end
        RestClient.post(url, params, :cookies => cookies, :accept => HTTP_ACCEPT_HEADER)
      end
      
      def put(url, params)
        if @config.request_filter
          @config.request_filter.call(@session_id, :put, url, params)
        end
        RestClient.put(url, params, :cookies => cookies, :accept => HTTP_ACCEPT_HEADER)
      end
      
      def delete(url, params)
        if @config.request_filter
          @config.request_filter.call(@session_id, :delete, url, params)
        end
        RestClient.delete(url, params, :cookies => cookies, :accept => HTTP_ACCEPT_HEADER)
      end

      def head(url, params)
        if @config.request_filter
          @config.request_filter.call(@session_id, :delete, url, params)
        end
        RestClient.head(url, params, :cookies => cookies, :accept => HTTP_ACCEPT_HEADER)
      end
  end
end
