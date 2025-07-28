class Athena::Framework::Exception::FileNotFound < ::File::NotFoundError
  include Athena::Framework::Exception::File
end
