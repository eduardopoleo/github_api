module Reports
  module Storage
    class Memory
      def initialize(hash={})
        @hash = hash
      end

      def read(key)
        @hash[key] #key is the url. This method is to see the response
      end

      def write(key, value)
        @hash[key] = value # this is the setter method
      end
    end
  end
end
