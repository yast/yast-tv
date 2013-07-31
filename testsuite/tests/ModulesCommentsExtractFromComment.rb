# encoding: utf-8

module Yast
  class ModulesCommentsExtractFromCommentClient < Client
    def main
      Yast.import "ModulesComments"
      Yast.include self, "testsuite.rb"

      # nil
      DUMP(ModulesComments.ExtractFromComment(nil))

      # Empty, no colon
      DUMP(ModulesComments.ExtractFromComment(""))

      # Just the colon
      DUMP(ModulesComments.ExtractFromComment(":"))

      # Empty UK, name is present
      DUMP(ModulesComments.ExtractFromComment(":Name"))

      # UK is present, empty name
      DUMP(ModulesComments.ExtractFromComment("123.456:"))

      # Empty UK + additional whitespace, name is present
      DUMP(ModulesComments.ExtractFromComment("#\t :Some name\n"))

      # More mathing lines, the last (with UK and name) is the right one
      DUMP(
        ModulesComments.ExtractFromComment(
          "#\n" +
            "\n" +
            "# u.k:This is not true\n" +
            "# 654.321:This is true\n" +
            "# \n"
        )
      )

      # Name with colons
      DUMP(ModulesComments.ExtractFromComment("# u.k:::Name::with::colons::"))

      # Usual comment
      DUMP(
        ModulesComments.ExtractFromComment(
          "# YaST2 configured TV card\n# 123.456:My TV Card\n"
        )
      )

      nil
    end
  end
end

Yast::ModulesCommentsExtractFromCommentClient.new.main
