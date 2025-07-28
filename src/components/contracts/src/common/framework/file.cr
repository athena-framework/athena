require "./abstract_file"

# Represents a file on the filesystem without opening a file descriptor.
struct Athena::Framework::File < Athena::Framework::AbstractFile
end
