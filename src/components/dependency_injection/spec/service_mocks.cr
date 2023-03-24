# #################
# # MULTIPLE TYPE #
# #################
# module TransformerInterface
#   abstract def transform
# end

# @[ADI::Register(alias: TransformerInterface, type: TransformerInterface, public: true)]
# struct ReverseTransformer
#   include TransformerInterface

#   def transform
#   end
# end

# @[ADI::Register]
# struct ShoutTransformer
#   include TransformerInterface

#   def transform
#   end
# end

# @[ADI::Register(public: true)]
# class TransformerAliasClient
#   getter service

#   def initialize(transformer : TransformerInterface)
#     @service = transformer
#   end
# end

# @[ADI::Register(public: true)]
# class TransformerAliasNameClient
#   getter service

#   def initialize(shout_transformer : TransformerInterface)
#     @service = shout_transformer
#   end
# end

# @[ADI::Register(public: true)]
# class ProxyTransformerAliasClient
#   getter service_one, shout_transformer

#   def initialize(
#     @service_one : ADI::Proxy(TransformerInterface),
#     @shout_transformer : ADI::Proxy(ShoutTransformer)
#   )
#   end
# end

# ######################
# # OVERRIDING ALIASES #
# ######################
# module ConverterInterface
# end

# @[ADI::Register(alias: ConverterInterface)]
# struct ConverterOne
#   include ConverterInterface
# end

# @[ADI::Register(alias: ConverterInterface, public_alias: true)]
# struct ConverterTwo
#   include ConverterInterface
# end
