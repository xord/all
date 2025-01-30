module Xot


  module Hookable

    def hook(name, &block)
      singleton_class.__send__ :define_method, name, &block
      self
    end

    def on(name, &block)
      hook "on_#{name}", &block
    end

    def before(name, &block)
      hook name do |*a, **k, &b|
        super(*a, **k, &b) unless block.call(*a, **k, &b) == :skip
      end
    end

    def after(name, &block)
      hook name do |*a, **k, &b|
        ret = super(*a, **k, &b)
        block.call(*a, **k, &b)
        ret
      end
    end

  end# Hookable


end# Xot
