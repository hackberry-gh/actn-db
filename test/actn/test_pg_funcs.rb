require 'minitest_helper'

module Actn
  module DB
    class TestPgFuncs < MiniTest::Test

      def setup
        DB.exec_func :create_table , 'public', 'funkytests'       
      end
      
      def teardown
        DB.exec_func :drop_table , 'public', 'funkytests'
      end
      
      # def test_find_model
      #   DB.exec_func(:upsert_model, 'public', {name: "Bonzo"}.to_json)
      #   assert_match /"name":"Bonzo"/, DB.exec_func(:find_model, "Bonzo")
      #   DB.exec_func(:delete_model, 'public', 'Bonzo')
      # end
      
      # def test_insert_delete_model
      #   foo = DB.exec_func(:upsert_model, 'public', Oj.dump({name: "Foo"}))
      #   assert_match /"name":"Foo"/, foo
      #   DB.exec_func(:delete_model, 'public', 'Foo')
      # end
      
      def test_upsert
        assert_match /"name":"Baz"/, DB.exec_func(:upsert, 'public', 'funkytests', Oj.dump({name: "Baz"}))
      end

      def test_update
        DB.exec_func(:upsert, 'public', 'funkytests', Oj.dump({name: "Baz"}))
        assert_match /"name":"Baz-Updated"/, DB.exec_func(:update, 'public', 'funkytests', Oj.dump({name: "Baz-Updated"}), Oj.dump({name: "Baz"}))
      end  
      
      def test_query
        assert_match /0/, DB.exec_func(:query, 'public', 'funkytests', Oj.dump({select: "COUNT(id)"}))        
        
        5.times {|i| DB.exec_func(:upsert, 'public', 'funkytests', Oj.dump({name: "Baz #{i}", country: "GB"})) }
        DB.exec_func(:upsert, 'public', 'funkytests', Oj.dump({name: "Baz 6", country: "TR"}))
        
        assert_match /"name":"Baz 0"/, DB.exec_func(:query, 'public', 'funkytests', Oj.dump({select: ['name']}))
        
        assert_equal '[{"country":"GB","count":5},{"country":"TR","count":1}]', DB.exec_func(:query, 'public', 'funkytests', Oj.dump({select: 'COUNT(id)', distinct: "country"}))
        
        semicomp = DB.exec_func(:query, 'public', 'funkytests', Oj.dump({ 
          select: "EXTRACT('day' from __timestamp(data,'created_at')) as time, COUNT(id) as count",
          where: { "raw" => "DATE_TRUNC('month',__timestamp(data,'created_at')) = DATE_TRUNC('month',now())" },
          group_by: "time",
          order_by: "time"
        }) )
        assert_match /[{"time":(\d+),"count":6}]/, semicomp
        
      end
      
      def test_delete
        DB.exec_func(:delete, 'public', 'funkytests', Oj.dump({}))
      end

      def test_validate_so_find_model
        mdata = Oj.dump({
          name: "Supporter",
          schema: {
          type: 'object',
          id: "#supporter",
          title: "Supporter",
          description: "Supporter Model",
          properties: {
            first_name: { type: 'string' }
          },
          required: ['first_name']
        }
        })
        DB.exec_func(:upsert, 'core', 'models', mdata)
        assert_match /errors/, DB.exec_func(:validate, 'Supporter', Oj.dump({}))
        DB.exec_func(:delete, 'core', 'models', Oj.dump({name: 'Supporter'}))
      end

      
    end

  end
end