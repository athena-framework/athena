# :nodoc:
#
# TODO: Currently extensions are registered via `ADI.register_extension` in which accepts the name of the extension as a string and a named tuple representing its schema.
# The schema uses TupleLiterals of TypeDeclaration to represent the name, type, and default value of each option.
# This works fine, but requires the extension creator to manually document the possible configuration options manually in another location.
# A more robust future approach might be to do something more like `ADI.register_extension ATH::Extension`,
# where the type's getters/constructor may be used to represent the configuration options' name, type, and default value, and what they are used for.
# This way things would be automatically documented as new things are added/changed, and this compiler stage could consume the data from the type to do what it is currently doing.
module Athena::DependencyInjection::ServiceContainer::RegisterExtensions
  macro included
    macro finished
      {% verbatim do %}
        {%
          extensions_to_register = [] of Nil # 0: ext name, 1: ext type

          # Tuple of:
          # 0 - extension type option is defined in
          # 1 - the option itself
          #
          # keyed by the name of the extension
          to_process = {} of Nil => Nil

          # For each extension type, register its base type
          Object.all_subclasses.select(&.annotation(ADI::RegisterExtension)).each do |ext|
            ext_ann = ext.annotation ADI::RegisterExtension

            extensions_to_register << {ext_ann[0], ext}
          end

          # For each base type, determine all child extension types
          extensions_to_register.each do |(ext_name, ext)|
            ext.constants.reject(&.==("OPTIONS")).each do |sub_ext|
              extensions_to_register << {ext_name, parse_type("::#{ext}::#{sub_ext}").resolve}
            end
          end

          p! extensions_to_register

          # For each extension to register, build out an 1 dimensional array
          extensions_to_register.each do |(ext_name, ext)|
            if to_process[ext_name] == nil
              ext_options = to_process[ext_name] = [] of Nil
            end

            ext.constant("OPTIONS").each do |o|
              ext_options << {ext_name, ext, o}
            end
          end

          p! to_process

          puts ""
          puts ""
          pp CONFIG
        %}
      {% end %}
    end
  end
end
