# encoding: utf-8

module Yast
  class TvModuleParametersAsItemsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      TEST_It_Now("bttv", { "non_existing_parameter" => "its_value" })

      TEST_It_Now("bttv", { "tuner" => "1" })

      nil
    end

    def TEST_It_Now(s_module, params)
      params = deep_copy(params)
      DUMP("---------------")

      Tv.kernel_modules = nil
      items = Tv.ModuleParametersAsItems(Tv.kernel_modules, s_module, params)
      DUMP(items)


      Tv.kernel_modules = {}
      items = Tv.ModuleParametersAsItems(Tv.kernel_modules, s_module, params)
      DUMP(items)


      Tv.kernel_modules = {
        "bttv" => {
          "module_description" => "bttv - v4l driver module for bt848/878 based cards",
          "tuner"              => "specify installed tuner type"
        }
      }
      items = Tv.ModuleParametersAsItems(Tv.kernel_modules, s_module, params)
      DUMP(items)

      nil
    end
  end
end

Yast::TvModuleParametersAsItemsClient.new.main
