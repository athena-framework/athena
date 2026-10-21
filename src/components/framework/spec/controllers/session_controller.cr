require "../spec_helper"

class SessionController < ATH::Controller
  @[ARTA::Get("/session/visits")]
  def visits(session : AHTTP::Session) : Int32
    visits = (session.get?("visits", Int32) || 0) + 1
    session.set "visits", visits

    visits
  end

  @[ARTA::Get("/session/optional")]
  def optional(session : AHTTP::Session?) : Bool
    !session.nil?
  end

  @[ARTA::Post("/session/flash")]
  def add_flash(request : AHTTP::Request) : Nil
    request.session.flash_bag.add "notice", "Saved!"
  end

  @[ARTA::Get("/session/flash")]
  def flashes(request : AHTTP::Request) : Array(String)
    request.session.flash_bag.get "notice"
  end

  @[ARTA::Post("/session/logout")]
  def logout(session : AHTTP::Session) : Nil
    session.invalidate
  end

  @[ARTA::Get("/session/unused")]
  def unused : String
    "unused"
  end

  @[ARTA::Get("/session/stateless", stateless: true)]
  def stateless(session : AHTTP::Session) : Nil
    session.has? "visits"
  end
end
