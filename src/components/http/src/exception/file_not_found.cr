class Athena::HTTP::Exception::FileNotFound < ::File::NotFoundError
  include Athena::HTTP::Exception
end
