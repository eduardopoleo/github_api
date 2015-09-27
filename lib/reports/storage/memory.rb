module Reports
  module Storage
    class Memory
      def initialize(hash={})
        @hash = hash
      end

      def read(key)
        serialized_value = @hash[key]
        Marshal.load(serialized_value) if serialized_value
      end

      def write(key, value)
        serialized_value = Marshal.dump(value)
        @hash[key] = serialized_value # this is the setter method
      end
    end
  end
end
