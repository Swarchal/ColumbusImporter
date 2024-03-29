#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## A static text control displays one or more lines of read-only text.
#
## :Appearance:
##   .. image:: images/wStaticText.png
#
## :Superclass:
##   `wControl <wControl.html>`_
##
## :Styles:
##   ==============================  =============================================================
##   Styles                          Description
##   ==============================  =============================================================
##   wAlignLeft                      Align the text to the left.
##   wAlignRight                     Align the text to the right.
##   wAlignCentre                    Center the text (horizontally).
##   wAlignCenter                    Center the text (horizontally).
##   wAlignMiddle                    Center the text (vertically).
##   wAlignLeftNoWordWrap            Align the text to the left, but words are not wrapped
##   ==============================  =============================================================
#
## :Events:
##   `wCommandEvent <wCommandEvent.html>`_
##   ==============================   =============================================================
##   wCommandEvent                    Description
##   ==============================   =============================================================
##   wEvent_CommandLeftClick          Clicked the left mouse button within the control.
##   wEvent_CommandLeftDoubleClick    Double-clicked the left mouse button within the control.
##   ===============================  =============================================================

const
  wAlignLeft* = SS_LEFT
  wAlignRight* = SS_RIGHT
  wAlignCentre* = SS_CENTER
  wAlignCenter* = SS_CENTER
  wAlignMiddle* = SS_CENTERIMAGE
  wAlignLeftNoWordWrap* = SS_LEFTNOWORDWRAP

method getBestSize*(self: wStaticText): wSize {.property.} =
  ## Returns the best acceptable minimal size for the control.
  result = getTextFontSize(self.getLabel(), self.mFont.mHandle, self.mHwnd)
  result.width += 2
  result.height += 2

method getDefaultSize*(self: wStaticText): wSize {.property.} =
  ## Returns the default size for the control.
  result = self.getBestSize()
  result.height = getLineControlDefaultHeight(self.mFont.mHandle)

proc wStaticText_DoCommand(event: wEvent) =
  # also used in wStaticBitmap
  let self = wAppWindowFindByHwnd(HWND event.mLparam)
  if self != nil:
    case HIWORD(event.mWparam)
    of STN_CLICKED:
      self.processMessage(wEvent_CommandLeftClick, event.mWparam, event.mLparam)
    of STN_DBLCLK:
      self.processMessage(wEvent_CommandLeftDoubleClick, event.mWparam, event.mLparam)
    else: discard

method release(self: wStaticText) =
  self.mParent.systemDisconnect(self.mCommandConn)

proc final*(self: wStaticText) =
  ## Default finalizer for wStaticText.
  discard

proc init*(self: wStaticText, parent: wWindow, id = wDefaultID,
    label: string = "", pos = wDefaultPoint, size = wDefaultSize,
    style: wStyle = wAlignLeft) {.validate.} =
  ## Initializer.
  wValidate(parent, label)
  self.wControl.init(className=WC_STATIC, parent=parent, id=id, label=label,
    pos=pos, size=size, style=style or WS_CHILD or WS_VISIBLE or SS_NOTIFY)

  self.mFocusable = false

  self.mCommandConn = parent.systemConnect(WM_COMMAND, wStaticText_DoCommand)
  self.systemConnect(WM_SIZE) do (event: wEvent):
    # when size change, StaticText should refresh itself, but windows system don't do it
    self.refresh()

proc StaticText*(parent: wWindow, id = wDefaultID,
    label: string = "", pos = wDefaultPoint, size = wDefaultSize,
    style: wStyle = wAlignLeft): wStaticText {.inline, discardable.} =
  ## Constructor, creating and showing a text control.
  wValidate(parent, label)
  new(result, final)
  result.init(parent, id, label, pos, size, style)
