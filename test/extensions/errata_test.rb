require 'rubygems'
require 'minitest/autorun'

require './lib/runcible'
require './test/extensions/unit_base'
require './test/support/repository_support'

module Extensions
  class TestErrata < MiniTest::Unit::TestCase
    def self.before_suite
      self.support = RepositorySupport.new
      @@extension = TestRuncible.server.extensions.errata
      self.support.create_and_sync_repo(:importer => true)
    end

    def self.after_suite
      self.support.destroy_repo
    end

    def test_all
      response = @@extension.all

      assert_equal 200, response.code
      refute_empty response
    end

    def test_find
      id = @@extension.all.sort_by { |p| p['id'] }.first['id']
      response = @@extension.find(id)

      refute_empty response
      assert_equal id, response['id']
    end

    def test_find_by_unit_id
      id = @@extension.all.sort_by { |p| p['id'] }.first['_id']
      response = @@extension.find_by_unit_id(id)

      refute_empty response
      assert_equal id, response['_id']
    end

    def test_find_unknown
      response = @@extension.find_all(['f'])

      assert_empty response
    end

    def test_find_all_by_unit_ids
      id = @@extension.all.sort_by { |p| p['_id'] }.first['_id']
      response = @@extension.find_all_by_unit_ids([id])

      refute_empty response
      assert_equal id, response.first['_id']
    end

    def test_find_all
      pkgs = @@extension.all.sort_by { |p| p['id'] }
      ids = pkgs[0..2].map { |p| p['id'] }
      response = @@extension.find_all(ids)

      assert_equal 200, response.code
      assert_equal ids.length, response.length
    end
  end

  class TestErrataCopy < UnitCopyBase
    def self.extension_class
      TestRuncible.server.extensions.errata
    end

    def test_copy
      response = self.class.extension_class.copy(RepositorySupport.repo_id, self.class.clone_name)

      tasks = assert_async_response(response)
      assert_includes tasks.first['tags'], 'pulp:action:associate'
    end
  end

  class TestErrataUnassociate < UnitUnassociateBase
    def self.extension_class
      TestRuncible.server.extensions.errata
    end

    def setup
      task = TestRuncible.server.extensions.repository.unit_copy(self.class.clone_name, RepositorySupport.repo_id)
      self.class.support.wait_on_response(task)
    end

    def test_unassociate_ids_from_repo
      ids = content_ids(RepositorySupport.repo_id)
      refute_empty ids
      response = self.class.extension_class.unassociate_ids_from_repo(self.class.clone_name, [ids.first])

      assert_async_response(response)
      assert_equal((ids.length - 1), content_ids(self.class.clone_name).length)
    end

    def test_unassociate_unit_ids_from_repo
      ids = unit_ids(RepositorySupport.repo_id)
      refute_empty ids
      response = self.class.extension_class.unassociate_unit_ids_from_repo(self.class.clone_name, [ids.first])

      assert_async_response(response)
      assert_equal((ids.length - 1), unit_ids(self.class.clone_name).length)
    end

    def test_unassociate_from_repo
      ids = unit_ids(RepositorySupport.repo_id)
      refute_empty ids
      response = self.class.extension_class.unassociate_from_repo(self.class.clone_name,
                                                              :association => {'unit_id' => {'$in' => [ids.first]}})

      assert_async_response(response)
      assert_equal((ids.length - 1), unit_ids(self.class.clone_name).length)
    end
  end
end
