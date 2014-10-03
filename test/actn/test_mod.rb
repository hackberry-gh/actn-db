require 'minitest_helper'
require 'actn/db/mod'

module Actn
  module DB
    class TestMod < MiniTest::Test
      
      class Boy < Mod
        self.table = "boys"
        self.schema = "public"   
        data_attr_accessor :team     
      end

      def setup
        DB.exec_func :create_table , 'public', 'boys'       
      end
      
      def teardown
        DB.exec_func :drop_table , 'public', 'boys'            
      end
      
      def test_set_crud
        
        boy = Boy.create(team: "Hamstead")
        assert boy.persisted?
        
        boy.update(team: "Norfolk")
        assert "Norfolk", boy.team
        
        same_boy = Boy.find(boy.uuid)
        assert "Norfolk", same_boy.team
        
        same_boy.destroy
        
        assert 0, Boy.count
        
        Boy.delete_all
        
      end
      
      def test_finders
        boy = Boy.create(team: "Hamstead")
        assert_raises(ArgumentError){ Boy.find_by }
        refute Boy.find_by({})
        refute Boy.find_by({falan: "filan"})
        assert Boy.find_by(team: "Hamstead")
        
      end
         

    end

  end
end