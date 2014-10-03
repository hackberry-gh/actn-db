require 'minitest_helper'
require 'actn/db/set'


module Actn
  module DB
    class TestSet < MiniTest::Test

      def setup
        DB.exec_func :create_table , 'public', 'kids'       
      end
      
      def teardown
        DB.exec_func :drop_table , 'public', 'kids'            
      end
      
      def test_set_crud
        
        assert_equal Set['kids'], Set['kids']
        
        assert_match /Belgium/, Set['kids'].upsert(age: 12, city: "Belgium", name: random_str)
        
        assert_match /Belgium/, Set['kids'].query(where: { age: [ "<" , 24 ] } )
        
        assert_match /red/, Set['kids'].update({color: "red"}, {age: 12})
        
        assert_match /1/, Set['kids'].count
        
        Set['kids'].delete_all
        
      end
      
      def test_validate_and_upsert
        mdata = Oj.dump({ name: "Supporter", schema: {
          type: 'object',
          id: "#supporter",
          title: "Supporter", 
          description: "Supporter Model",
          properties: {
            city: { type: 'string' }
          },
          required: ['city']
        }
        })
        DB.exec_func(:upsert, 'core', 'models', mdata)

        assert_match /errors/, Set['supporters'].validate_and_upsert(age: 12, name: random_str)
        assert_match /Belgium/, Set['supporters'].validate_and_upsert(age: 12, city: "Belgium", name: random_str)        

        DB.exec_func(:delete, 'core', 'models', Oj.dump({name: 'Supporter'}))
      end
         

    end

  end
end