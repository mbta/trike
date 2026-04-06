defprotocol Trike.CloudEvent.Manifest do
  @moduledoc """

  A protocol for specifying a set of cloud events to be produced for a single
  parsed OCS message, keeping in mind that some OCS messages may require us
  to emit multiple events to allow for backward compatibility. For example, if we
  introduce a breaking change in the format of TSCH_TAG events, then the manifest
  for TSCH_TAG should include both the original v1 event, and the new v2 event
  until v1 can be safely phased out.
  """

  @doc """
  Return a list of tuples specifying events to be emitted.

  Each tuple should be of the form: { event_type, specversion, data }

  These values will be used for the `type`, `specversion`, and `data`
  fields of the CloudEvents.
  """
  @spec manifest_from_ocs(t()) :: list({String.t(), String.t(), any()})
  def manifest_from_ocs(parsed_event)
end
