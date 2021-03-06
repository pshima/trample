module Trample
  class Page
    attr_reader :request_method, :think_time

    def initialize(request_method, url, think_time, parameters = {})
      @request_method = request_method
      @url            = url
      @think_time     = think_time
      @parameters     = parameters
    end

    def parameters
      proc_params? ? @parameters.call : @parameters
    end

    def ==(other)
      other.is_a?(Page) && 
        other.request_method == request_method &&
        other.url == url &&
        other.think_time == think_time
    end

    def url
      proc_params? ? interpolated_url : @url
    end
    
    protected
      def proc_params?
        @parameters.is_a?(Proc)
      end

      def interpolated_url
        params = parameters # cache called proc
        url    = @url.dup
        url.scan(/\:[A-Za-z_]\w+/).each do |m|
          url.gsub!(m, params[m.gsub(/:/, '').to_sym].to_s)
        end
        url
      end
  end
end
