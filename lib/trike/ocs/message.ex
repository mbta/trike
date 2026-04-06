defmodule OCS.Message do
  @type t ::
          OCS.Message.TschNewMessage.t()
          | OCS.Message.TschConMessage.t()
          | OCS.Message.TschAsnMessage.t()
          | OCS.Message.TschRldMessage.t()
          | OCS.Message.TschDstMessage.t()
          | OCS.Message.TschDelMessage.t()
          | OCS.Message.TschLnkMessage.t()
          | OCS.Message.TschOffMessage.t()
          | OCS.Message.TschTagMessage.t()

  # other message types omitted for now
  # OCS.Message.TmovDelMessage.t()
  # | OCS.Message.TmovHeavyRailMessage.t()
  # | OCS.Message.TmovLightRailMessage.t()
  # | OCS.Message.DiagnosticsMessage.t()
  # | OCS.Message.DeviSgMessage.t()
  # | OCS.Message.DeviMdMessage.t()
  # | OCS.Message.RawGpsMessage.t()
end
