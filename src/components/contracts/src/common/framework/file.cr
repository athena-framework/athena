require "./abstract_file"

# Represents a file on the filesystem without opening a file descriptor.
# See [ATH::AbstractFile][] for the available API.
struct Athena::Framework::File < Athena::Framework::AbstractFile
end
