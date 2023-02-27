# -*- coding: utf-8 -*-


require 'reflex/model'


module Reflex


  module ModelOwner

    attr_reader :model

    def model=(model)
      return if model == @model
      @model.remove_handler self if @model
      @model = model
      @model.add_handler self    if @model
      model
    end

    def data=(data)
      unless data.nil?
        self.model = Model.new unless @model
        @model.data = data
      else
        self.model = nil
      end
      data
    end

    def data()
      @model ? @model.data : nil
    end

    def invoke(*args)
      @model.invoke(*args) if @model
    end

    def on_data_attach(e)
      invoke :update, {}, only: self
    end

    def on_data_detach(e)
      invoke :update, {}, only: self
    end

    [:int, :float, :string, :[], :[]=].each do |name|
      define_method name do |*args|
        @model ? @model.send(name, *args) : nil
      end
    end

  end# ModelOwner


end# Reflex
