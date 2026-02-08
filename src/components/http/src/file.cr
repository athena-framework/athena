require "./abstract_file"

# Represents a file on the filesystem without opening a file descriptor.
# See `AHTTP::AbstractFile` for the available API.
struct Athena::HTTP::File < Athena::HTTP::AbstractFile
end
