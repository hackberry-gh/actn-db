require 'minitest_helper'
require 'actn/db/model'
require 'actn/db/set'

module Actn
  module DB
    class TestModel < MiniTest::Test


      def test_validation
        model = Model.create()
        # puts model.inspect
        assert model.errors.any?
        refute model.persisted?
        refute model.destroy
      end
      
      def test_model_with_full_schema
        json = '{"name":"ModelName","schema":{"title":"Model Name","type":"object","properties":{"firstName":{"type":"string"},"lastName":{"type":"string"},"age":{"description":"Age in years","type":"integer","minimum":0}},"required":["firstName","lastName"]},"indexes":[{"cols":{"apikey":"text"},"unique":true}],"hooks":{"after_create":[{"name":"Trace"},{"name":"Trace"}]}}'
        data  = Oj.load(json)

        model = Model.create(data)
        # puts "----"
        # puts model.inspect
        # puts "----"
        assert model.persisted?

        assert_match /0/, Set['ModelName'.tableize].count

        assert model.update({"indexes" => [{"cols" => {"first_name" => "text"},"unique" => true}]})

        model.update(name: "Cannot change")

        assert_equal "ModelName", model.name

        samenamedmodel =  Model.create(data)
        puts samenamedmodel.errors.inspect
        refute samenamedmodel.persisted?

        model.destroy
        # puts "DESTRO #{model.destroy.inspect}"
        #
        # puts "ALL #{Set.new('core','models').all}"
      end

    end

  end
end