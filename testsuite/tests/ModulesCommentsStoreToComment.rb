# encoding: utf-8

module Yast
  class ModulesCommentsStoreToCommentClient < Client
    def main
      Yast.import "ModulesComments"
      Yast.include self, "testsuite.rb"

      DUMP([ModulesComments.StoreToComment(nil, nil)])

      DUMP([ModulesComments.StoreToComment("Test TV Card", nil)])

      DUMP([ModulesComments.StoreToComment(nil, "dn0t.+xOL8ZCSAQC")])

      DUMP([ModulesComments.StoreToComment("My TV Card", "nd54sdde8d25cv45")])

      nil
    end
  end
end

Yast::ModulesCommentsStoreToCommentClient.new.main
