module Xot


  module Setter

    def set(*args)
      first = args.shift
      if first.kind_of? Hash
        first.each {|name, value| set_value__ name, value}
      else
        set_value__ first, *args
      end
    end

    private

      def set_value__(name, *values)
        raise ArgumentError, "set '#{values}' to '#{name}'" if
          !name || name.empty? || values.empty?
        __send__ "#{name}=", *values
      end

  end# Setter


end# Xot
