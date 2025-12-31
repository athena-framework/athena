# :nodoc:
#
# Normalizes service tags and populates TAG_HASH.
# Runs after RegisterServices and ProcessAutoconfigureAnnotations.
module Athena::DependencyInjection::ServiceContainer::ProcessTags
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            klass = definition["class"]
            normalized_tags = {} of Nil => Nil

            (definition["tags"] || [] of Nil).each do |tag|
              name, attributes = if tag.is_a?(StringLiteral)
                                   {tag, {} of Nil => Nil}
                                 elsif tag.is_a?(Path)
                                   {tag.resolve.id.stringify, {} of Nil => Nil}
                                 elsif tag.is_a?(NamedTupleLiteral) || tag.is_a?(HashLiteral)
                                   unless tag[:name]
                                     tag.raise "Failed to register service '#{service_id.id}' (#{klass}). Tag must have a name."
                                   end

                                   # Resolve a constant to its value if used as a tag name
                                   if tag["name"].is_a? Path
                                     tag["name"] = tag["name"].resolve
                                   end

                                   # TODO: Replace this with `#delete` if/when it's ever released
                                   # https://github.com/crystal-lang/crystal/pull/9837
                                   attributes = {} of Nil => Nil

                                   tag.each do |k, v|
                                     attributes[k.id.stringify] = v unless k.id.stringify == "name"
                                   end

                                   {tag["name"], attributes}
                                 else
                                   tag.raise "Tag must be a 'StringLiteral' or 'NamedTupleLiteral', got '#{tag.class_name.id}'."
                                 end

              normalized_tags[name] = [] of Nil if normalized_tags[name] == nil
              normalized_tags[name] << attributes
              normalized_tags[name] = normalized_tags[name].uniq

              TAG_HASH[name] = [] of Nil if TAG_HASH[name] == nil
              TAG_HASH[name] << {service_id, attributes}
              TAG_HASH[name] = TAG_HASH[name].uniq
            end

            definition["tags"] = normalized_tags
          end
        %}
      {% end %}
    end
  end
end
