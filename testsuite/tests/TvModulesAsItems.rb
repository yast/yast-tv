# encoding: utf-8

module Yast
  class TvModulesAsItemsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # testing with different values of selected_module
      TEST_It_Now(nil)

      TEST_It_Now("bttv")

      TEST_It_Now("zoran")

      nil
    end

    def TEST_It_Now(s_module)
      DUMP("---------------")

      # kernel_modules_database cannot be nil (see ReadKernelModules)
      # Tv::kernel_modules = nil;
      # list items = Tv::ModulesAsItems(s_module);
      # DUMP(items);


      Tv.kernel_modules = {}
      items = Tv.ModulesAsItems(Tv.kernel_modules, s_module)
      DUMP(items)


      Tv.kernel_modules = {
        "bttv"  => {
          "module_description" => "bttv - v4l driver module for bt848/878 based cards"
        },
        "zoran" => {
          "module_description" => "Zoran ZR36120 based framegrabber"
        }
      }
      items = Tv.ModulesAsItems(Tv.kernel_modules, s_module)
      DUMP(items)

      nil
    end
  end
end

Yast::TvModulesAsItemsClient.new.main
