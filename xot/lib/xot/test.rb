# -*- coding: utf-8 -*-


module Xot


  module Test

    def assert_not(expression, *args)
      assert !expression, *args
    end

    def assert_not_includes(collection, obj, *args)
      assert !collection.include?(obj), *args
    end

  end# Test


end# Xot
