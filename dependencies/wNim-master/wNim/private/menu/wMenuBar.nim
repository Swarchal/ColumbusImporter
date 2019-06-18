#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## A menubar is a series of menus accessible from the top of a frame.
#
## :Superclass:
##   `wMenuBase <wMenuBase.html>`_
#
## :Seealso:
##   `wMenu <wMenu.html>`_
##   `wMenuItem <wMenuItem.html>`_

proc refresh*(self: wMenuBar) {.validate.} =
  ## Redraw the menubar.
  for frame in self.mParentFrameSet:
    if frame.mMenuBar == self:
      DrawMenuBar(frame.mHwnd)

proc attach*(self: wMenuBar, frame: wFrame) {.validate.} =
  ## Attach a menubar to frame window.
  wValidate(frame)
  frame.mMenuBar = self
  if SetMenu(frame.mHwnd, self.mHmenu) != 0:
    DrawMenuBar(frame.mHwnd)
    self.mParentFrameSet.incl frame

proc detach*(self: wMenuBar, frame: wFrame) {.validate.} =
  ## Detach a menubar from the frame.
  wValidate(frame)
  if frame.mMenuBar == self:
    frame.mMenuBar = nil
    SetMenu(frame.mHwnd, 0)
    DrawMenuBar(frame.mHwnd)
  if frame in self.mParentFrameSet:
    self.mParentFrameSet.excl frame

proc detach*(self: wMenuBar) {.validate.} =
  ## Detach a menubar from all frames.
  for frame in self.mParentFrameSet:
    self.detach(frame)

proc isAttached*(self: wMenuBar): bool {.validate.} =
  ## Return true if a menubar is attached to some frame window.
  result = self.mParentFrameSet.len > 0

proc isAttached*(self: wMenuBar, frame: wFrame): bool {.validate.} =
  ## Return true if a menubar is attached to the frame window.
  wValidate(frame)
  result = frame in self.mParentFrameSet

proc insert*(self: wMenuBar, pos: int, menu: wMenu, text: string,
    bitmap: wBitmap = nil) {.validate.} =
  ## Inserts the menu at the given position into the menubar.
  wValidate(menu, text)
  var
    text = text
    pos = pos
    count = self.mMenuList.len

  if text.len == 0: text = ""
  if pos < 0: pos = count
  elif pos > count: pos = count

  var menuItemInfo = MENUITEMINFO(
    cbSize: sizeof(MENUITEMINFO),
    fMask: MIIM_DATA or MIIM_FTYPE or MIIM_SUBMENU or MIIM_STRING,
    dwItemData: cast[ULONG_PTR](menu),
    fType: MFT_STRING,
    hSubMenu: menu.mHmenu,
    dwTypeData: T(text))

  if bitmap != nil:
    menu.mBitmap = bitmap
    menuItemInfo.fMask = menuItemInfo.fMask or MIIM_BITMAP

    when defined(useWinXP):
      menuItemInfo.hbmpItem = HBMMENU_CALLBACK
      # don't use callback if windows version is vista or latter
      if wGetWinVersion() > 6.0: menuItemInfo.hbmpItem = bitmap.mHandle

    else:
      menuItemInfo.hbmpItem = bitmap.mHandle

  if InsertMenuItem(self.mHmenu, pos, true, menuItemInfo) != 0:
    self.mMenuList.insert(menu, pos)
    menu.mParentMenuCountTable.inc(self, 1)
    self.refresh()

proc append*(self: wMenuBar, menu: wMenu, text: string, bitmap: wBitmap = nil)
    {.validate, inline.} =
  ## Adds the menu to the end of the menubar.
  wValidate(menu, text)
  self.insert(pos = -1, menu=menu, text=text, bitmap=bitmap)

proc enable*(self: wMenuBar, pos: int, flag = true) {.validate.} =
  ## Enables or disables a whole menu.
  if pos >= 0 and pos < self.mMenuList.len:
    wEnableMenu(self.mHmenu, pos, flag)

proc disable*(self: wMenuBar, pos: int) {.validate, inline.} =
  ## Disables a whole menu.
  self.enable(pos, false)

proc isEnabled*(self: wMenuBar, pos: int): bool {.validate.} =
  ## Returns true if the menu with the given index is enabled.
  if pos >= 0 and pos < self.mMenuList.len:
    result = wIsMenuEnabled(self.mHmenu, pos)

iterator find*(self: wMenuBar, menu: wMenu): int {.validate.} =
  ## Iterates over each index of menu in menubar.
  wValidate(menu)
  for i, m in self.mMenuList:
    if m == menu:
      yield i

proc find*(self: wMenuBar, menu: wMenu): int {.validate.} =
  ## Find the first index of menu or wNotFound(-1) if not found.
  wValidate(menu)
  for i in self.find(menu):
    return i
  result = wNotFound

iterator find*(self: wMenuBar, text: string): int {.validate.} =
  ## Iterates over each index with the given title.
  # don's use mTitle here, because a menu may be attach a frame twice,
  # or different frame?
  wValidate(text)
  var buffer = T(65536)
  for i in 0..<GetMenuItemCount(self.mHmenu):
    let length = wGetMenuItemString(self.mHmenu, i, buffer)
    if length != 0 and $buffer[0..<length] == text:
      yield i

proc find*(self: wMenuBar, text: string): int {.validate.} =
  ## Find the first index with the given title or wNotFound(-1) if not found.
  wValidate(text)
  for i in self.find(text):
    return i
  result = wNotFound

iterator findMenu*(self: wMenuBar, text: string): wMenu {.validate.} =
  ## Iterates over each wMenu object with the given title.
  wValidate(text)
  for i in self.find(text):
    yield self.mMenuList[i]

proc findMenu*(self: wMenuBar, text: string): wMenu {.validate.} =
  ## Find the first wMenu object with the given title or nil if not found.
  wValidate(text)
  for menu in self.findMenu(text):
    return menu

iterator findText*(self: wMenuBar, text: string): int {.validate.} =
  ## Iterates over each index with the given title (not include any accelerator
  ## characters).
  wValidate(text)
  var buffer = T(65536)
  for i in 0..<GetMenuItemCount(self.mHmenu):
    let length = wGetMenuItemString(self.mHmenu, i, buffer)
    if length != 0 and replace($buffer[0..<length], "&", "") == text:
      yield i

proc findText*(self: wMenuBar, text: string): int {.validate.} =
  ## Find the first index with the given title (not include any accelerator
  ## characters), wNotFound(-1) if not found.
  wValidate(text)
  for i in self.findText(text):
    return i
  result = wNotFound

iterator findMenuText*(self: wMenuBar, text: string): wMenu {.validate.} =
  ## Iterates over each wMenu object with the given title (not include any
  ## accelerator characters).
  wValidate(text)
  for i in self.findText(text):
    yield self.mMenuList[i]

proc findMenuText*(self: wMenuBar, text: string): wMenu {.validate.} =
  ## Find the first wMenu object with the given title (not include any
  ## accelerator characters), nil if not found.
  wValidate(text)
  for menu in self.findMenuText(text):
    return menu

proc getMenu*(self: wMenuBar, pos: int): wMenu {.validate, property.} =
  ## Returns the menu at pos, nil if index out of bounds.
  if pos >= 0 and pos < self.mMenuList.len:
    result = self.mMenuList[pos]

proc getLabel*(self: wMenuBar, pos: int): string {.validate, property.} =
  ## Returns the label of a top-level menu.
  if pos >= 0 and pos < self.mMenuList.len:
    var buffer = T(65536)
    let length = wGetMenuItemString(self.mHmenu, pos, buffer)
    if length != 0:
      result = $buffer[0..<length]

proc getLabelText*(self: wMenuBar, pos: int): string {.validate, property.} =
  ## Returns the label of a top-level menu, not include any accelerator characters.
  wValidate(self)
  result = self.getLabel(pos)
  if result.len != 0:
    result = result.replace("&", "")

proc setLabel*(self: wMenuBar, pos: int, text: string) {.validate, property.} =
  ## Sets the label of a top-level menu.
  wValidate(text)
  if pos >= 0 and pos < self.mMenuList.len and text.len != 0:
    var menuItemInfo = MENUITEMINFO(
      cbSize: sizeof(MENUITEMINFO),
      fMask: MIIM_STRING,
      dwTypeData: T(text))
    SetMenuItemInfo(self.mHmenu, pos, true, menuItemInfo)

proc remove*(self: wMenuBar, pos: int): wMenu {.validate, discardable.} =
  ## Removes the menu from the menubar and returns the menu object.
  if pos >= 0 and pos < self.mMenuList.len:
    if RemoveMenu(self.mHmenu, pos, MF_BYPOSITION) != 0:
      result = self.mMenuList[pos]
      result.mParentMenuCountTable.inc(self, -1)
      self.mMenuList.delete(pos)
    self.refresh()

proc remove*(self: wMenuBar, menu: wMenu) {.validate.} =
  ## Find and remove all the menu object from the menubar.
  wValidate(menu)
  while true:
    let pos = self.find(menu)
    if pos == wNotFound: break
    self.remove(pos)

proc replace*(self: wMenuBar, pos: int, menu: wMenu, text: string,
    bitmap: wBitmap = nil): wMenu {.validate, discardable.} =
  ## Replaces the menu at the given position with another one.
  ## Return the old menu object.
  wValidate(menu)
  if pos >= 0 and pos < self.mMenuList.len:
    result = self.remove(pos)
    self.insert(pos, menu=menu, text=text, bitmap=bitmap)

proc delete*(self: wMenuBar) {.validate.} =
  ## Delete the menubar.
  self.detach()
  if self.mHmenu != 0:
    # use GetMenuItemCount(self.mHmenu) instead of mMenuList.len to ensure we
    # remove all menu.
    for i in 0..<GetMenuItemCount(self.mHmenu):
      RemoveMenu(self.mHmenu, 0, MF_BYPOSITION)
    DestroyMenu(self.mHmenu)

    for i in 0..<self.mMenuList.len:
      self.mMenuList[i].mParentMenuCountTable.inc(self, -1)

    self.mMenuList = @[]
    self.mHmenu = 0

proc getHandle*(self: wMenuBar): HMENU {.validate, property, inline.} =
  ## Get system handle of this menubar.
  result = self.mHmenu

proc getCount*(self: wMenuBar): int {.validate, property, inline.} =
  ## Returns the number of menus in this menubar.
  result = GetMenuItemCount(self.mHmenu)

iterator items*(self: wMenuBar): wMenu {.validate.} =
  ## Items iterator for menus in a menubar.
  for menu in self.mMenuList:
    yield menu

iterator pairs*(self: wMenuBar): (int, wMenu) {.validate.} =
  ## Iterates over each menu of menubar. Yields ``(index, [index])`` pairs.
  for i, menu in self.mMenuList:
    yield (i, menu)

proc `[]`*(self: wMenuBar, pos: int): wMenu {.validate, inline.} =
  ## Returns the menu at pos.
  ## Raise error if index out of bounds.
  result = self.mMenuList[pos]

proc len*(self: wMenuBar): int {.validate, inline.} =
  ## Returns the number of wMenu objects in this menubar.
  ## This shoud be equal to getCount in most case.
  result = self.mMenuList.len

proc final*(self: wMenuBar) =
  ## Default finalizer for wMenuBar.
  self.delete()

proc init*(self: wMenuBar) {.validate.} =
  ## Initializer.
  self.mHmenu = CreateMenu()
  var menuInfo = MENUINFO(
    cbSize: sizeof(MENUINFO),
    fMask: MIM_STYLE,
    dwStyle: MNS_CHECKORBMP or MNS_NOTIFYBYPOS)
  SetMenuInfo(self.mHmenu, menuInfo)
  self.mMenuList = @[]

  # initSet is deprecated since v0.20
  when declared(initHashSet):
    self.mParentFrameSet = initHashSet[wFrame]()
  else:
    self.mParentFrameSet = initSet[wFrame]()

proc MenuBar*(): wMenuBar {.inline.} =
  ## Construct an empty menubar.
  new(result, final)
  result.init()

proc init*(self: wMenuBar, menus: openarray[(wMenu, string)]) {.validate.} =
  ## Initializer.
  self.init()
  for menu in menus:
    self.append(menu[0], menu[1])

proc MenuBar*(menus: openarray[(wMenu, string)]): wMenuBar {.inline.} =
  ## Construct a menubar from arrays of menus and titles.
  new(result, final)
  result.init(menus)

proc init*(self: wMenuBar, frame: wFrame, menus: openarray[(wMenu, string)] = [])
    {.validate.} =
  ## Initializer.
  wValidate(frame)
  self.init(menus)
  self.attach(frame)

proc MenuBar*(frame: wFrame, menus: openarray[(wMenu, string)] = []): wMenuBar
    {.inline.} =
  ## Construct a menubar from arrays of menus and titles, and attach it to frame window.
  wValidate(frame)
  new(result, final)
  result.init(frame, menus)