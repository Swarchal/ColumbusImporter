#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## These events are generated by wFrame when the mouse moves or clicks on the
## system tray icon.
#
## :Superclass:
##   `wEvent <wEvent.html>`_
#
## :Events:
##   ==============================  =============================================================
##   wTrayEvent                      Description
##   ==============================  =============================================================
##   wEvent_TrayLeftDown             The left button was pressed.
##   wEvent_TrayLeftUp               The left button was released.
##   wEvent_TrayRightDown            The right button was pressed.
##   wEvent_TrayRightUp              The right button was released.
##   wEvent_TrayLeftDoubleClick      The the left button was double-clicked
##   wEvent_TrayRightDoubleClick     The the middle button was double-clicked
##   wEvent_TrayMove                 The cursor moves.
##   wEvent_TrayBalloonTimeout       The balloon is dismissed because of a timeout.
##   wEvent_TrayBalloonClick         The balloon is dismissed because the user clicked the mouse.
##   ==============================  =============================================================

DefineIncrement(wEvent_TrayFirst):
  wEvent_TrayIcon
  wEvent_TrayLeftDown
  wEvent_TrayLeftUp
  wEvent_TrayRightDown
  wEvent_TrayRightUp
  wEvent_TrayLeftDoubleClick
  wEvent_TrayRightDoubleClick
  wEvent_TrayMove
  wEvent_TrayBalloonTimeout
  wEvent_TrayBalloonClick
  wEvent_TrayLast

proc isTrayEvent(msg: UINT): bool {.inline.} =
  msg in wEvent_TrayFirst..wEvent_TrayLast
