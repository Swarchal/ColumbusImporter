#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## This event is generated by wWindow when the mouse cursor is about to be set
## as a result of mouse motion. This event gives the application the chance to
## perform specific mouse cursor processing based on the current position of the
## mouse within the window. Use setCursor() to specify the cursor you want to be
## displayed.
#
## :Superclass:
##   `wEvent <wEvent.html>`_
#
## :Events:
##   ==============================  =============================================================
##   wSetCursorEvent                 Description
##   ==============================  =============================================================
##   wEvent_SetCursor                The mouse cursor is about to be set.
##   ==============================  =============================================================

const
  wEvent_SetCursor* = WM_APP + 3

proc isSetCursorEvent(msg: UINT): bool {.inline.} =
  msg == wEvent_SetCursor

method getCursor*(self: wSetCursorEvent): wCursor {.property, inline.} =
  ## Returns a reference to the cursor specified by this event.
  result = cast[wCursor](self.mLparam)

method setCursor*(self: wSetCursorEvent, cursor: wCursor) {.property, inline.} =
  ## Sets the cursor associated with this event.
  wValidate(cursor)
  self.mLparam = cast[LPARAM](cursor)
