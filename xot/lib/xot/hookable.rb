module Xot


  module Hookable

    def hook(name, &block)
      singleton_class.__send__ :define_method, name, &block
      self
    end

    def on(name, &block)
      hook name do |*a, &b|
        block.call(*a, &b)
      end
    end

    def before(name, &block)
      hook name do |*a, &b|
        super(*a, &b) unless block.call(*a, &b) == :skip
      end
    end

    def after(name, &block)
      hook name do |*a, &b|
        ret = super(*a, &b)
        block.call(*a, &b)
        ret
      end
    end

  end# Hookable


end# Xot
