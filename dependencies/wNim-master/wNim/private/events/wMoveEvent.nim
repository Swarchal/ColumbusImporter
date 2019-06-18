#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## These events are generated by wWindow when the window is moved or about to move.
#
## :Superclass:
##   `wEvent <wEvent.html>`_
#
## :Events:
##   ==============================  =============================================================
##   wMoveEvent                      Description
##   ==============================  =============================================================
##   wEvent_Move                     Window is moved.
##   wEvent_Moving                   Window is moving.
##   wEvent_Dragging                 Window is dragging by user. This event can be vetoed.
##   ==============================  =============================================================

const
  wEvent_Move* = WM_MOVE
  wEvent_Moving* = WM_MOVING
  wEvent_Dragging* = WM_APP + 56

proc isMoveEvent(msg: UINT): bool {.inline.} =
  msg in {wEvent_Move, wEvent_Moving, wEvent_Dragging}

method getPosition*(self: wMoveEvent): wPoint {.property.} =
  ## Returns the entire size of the window generating the size change event.
  if self.mMsg in {WM_MOVE, wEvent_Dragging}:
    result.x = GET_X_LPARAM(self.mLparam)
    result.y = GET_Y_LPARAM(self.mLparam)
  elif self.mMsg == WM_MOVING:
    var rect = toWRect(cast[PRECT](self.mLparam)[])
    result.x = rect.x
    result.y = rect.y

method setPosition*(self: wMoveEvent, x: int, y: int) {.property.} =
  if self.mMsg == WM_MOVING:
    var rect = toWRect(cast[PRECT](self.mLparam)[])
    rect.x = x
    rect.y = y
    cast[PRECT](self.mLparam)[] = toRect(rect)

method setPosition*(self: wMoveEvent, pos: wPoint) {.property.} =
  self.setPosition(pos.x, pos.y)