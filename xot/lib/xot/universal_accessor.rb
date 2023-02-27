# -*- coding: utf-8 -*-


module Xot


  module UniversalAccessor

    def universal_accessor(*names, **names_with_options)
      names.each              {|name|       define_universal_accessor name}
      names_with_options.each {|name, opts| define_universal_accessor name, opts}
    end

    private

      def define_universal_accessor(name, options = {})
        set = "ua_set_#{name}__"
        get = "ua_get_#{name}__"
        class_eval <<-END
          alias_method :#{set}, options[:writer] || :#{name}=
          alias_method :#{get}, options[:reader] || :#{name}
          private :#{set}, :#{get}
          def #{name}(*args, **kwargs)
            #{set}(*args, **kwargs) unless args.empty? && args.empty?
            #{get}
          end
        END
      end

  end# UniversalAccessor


end# Xot


class Module

  include Xot::UniversalAccessor

end# Module
