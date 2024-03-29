#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## This event is generated by wIpCtrl. The field value can be modified by
## setValue() in the event handler.
#
## :Superclass:
##   `wCommandEvent <wCommandEvent.html>`_
#
## :Events:
##   ==============================  =============================================================
##   wIpEvent                        Description
##   ==============================  =============================================================
##   wEvent_IpChanged                When the user changes a field or moves from one field to another.
##   ==============================  =============================================================

DefineIncrement(wEvent_IpFirst):
  wEvent_IpChanged

proc isIpEvent(msg: UINT): bool {.inline.} =
  msg == wEvent_IpChanged

method getIndex*(self: wIpEvent): int {.property, inline.} =
  ## The zero-based number of the field that was changed.
  result = self.mIndex

method getValue*(self: wIpEvent): int {.property, inline.} =
  ## Gets the new value of the field.
  result = self.mValue

method setValue*(self: wIpEvent, value: int) {.property, inline.} =
  ## Sets the new value of the field.
  self.mValue = value
