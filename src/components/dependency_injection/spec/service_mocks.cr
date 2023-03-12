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

# ##################
# # TAGGED SERVICE #
# ##################
# private PARTNER_TAG = "partner"

# enum Status
#   Active
#   Inactive
# end

# @[ADI::Register(_id: 1, name: "google", tags: [{name: PARTNER_TAG, priority: 5}])]
# @[ADI::Register(_id: 2, name: "facebook", tags: [PARTNER_TAG])]
# @[ADI::Register(_id: 3, name: "yahoo", tags: [{name: "partner", priority: 10}])]
# @[ADI::Register(_id: 4, name: "microsoft", tags: [PARTNER_TAG])]
# struct FeedPartner
#   getter id

#   def initialize(@id : Int32); end
# end

# @[ADI::Register(_services: "!partner", public: true)]
# class PartnerClient
#   getter services

#   def initialize(@services : Array(FeedPartner))
#   end
# end

# @[ADI::Register(_services: "!partner", public: true)]
# class PartnerNamedDefaultClient
#   getter services
#   getter status

#   def initialize(
#     @services : Array(FeedPartner),
#     @status : Status = Status::Active
#   )
#   end
# end

# @[ADI::Register(_services: "!partner", public: true)]
# record ProxyTagClient, services : Array(ADI::Proxy(FeedPartner))

# ######################
# # AUTO CONFIGURATION #
# ######################

# module ConfigInterface; end

# @[ADI::Register]
# record ConfigOne do
#   include ConfigInterface
# end

# @[ADI::Register]
# record ConfigTwo do
#   include ConfigInterface
# end

# @[ADI::Register(tags: [] of String)]
# record ConfigThree do
#   include ConfigInterface
# end

# @[ADI::Register]
# struct ConfigFour
# end

# @[ADI::Register(_configs: "!config", public: true)]
# record ConfigClient, configs : Array(ConfigInterface)

# ADI.auto_configure ConfigInterface, {tags: ["config"]}
# ADI.auto_configure ConfigFour, {public: true}
