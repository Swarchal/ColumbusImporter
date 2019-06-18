#====================================================================
#
#               wNim - Nim's Windows GUI Framework
#                 (c) Copyright 2017-2019 Ward
#
#====================================================================

## A cursor is a small bitmap usually used for denoting where the mouse pointer
## is. There are two special predefined cursor: wNilCursor and wDefaultCursor.
## See wWindow.setCursor() for details.
#
## :Superclass:
##    `wGdiObject <wGdiObject.html>`_
#
## :Seealso:
##    `wDC <wDC.html>`_
##    `wPredefined <wPredefined.html>`_
##    `wIconImage <wIconImage.html>`_
#
## :Enum:
##    ==============================  =============================================================
##    wStockCursor                    Description
##    ==============================  =============================================================
##    wCursorArrow                    Standard arrow
##    wCursorIbeam                    I-beam
##    wCursorWait                     Hourglass
##    wCursorCross                    Crosshair
##    wCursorUpArrow                  Vertical arrow
##    wCursorSizeNwse                 Double-pointed arrow pointing northwest and southeast
##    wCursorSizeNesw                 Double-pointed arrow pointing northeast and southwest
##    wCursorSizeWe                   Double-pointed arrow pointing west and east
##    wCursorSizeNs                   Double-pointed arrow pointing north and south
##    wCursorSizeAll                  Four-pointed arrow pointing north, south, east, and west
##    wCursorNo                       Slashed circle
##    wCursorHand                     Hand
##    wCursorAppStarting              Standard arrow and small hourglass
##    wCursorHelp                     Arrow and question mark
##    ==============================  =============================================================

type
  wStockCursor* = enum
    wCursorArrow = 32512
    wCursorIbeam = 32513
    wCursorWait = 32514
    wCursorCross = 32515
    wCursorUpArrow = 32516
    wCursorSize = 32640
    wCursorIcon = 32641
    wCursorSizeNwse = 32642
    wCursorSizeNesw = 32643
    wCursorSizeWe = 32644
    wCursorSizeNs = 32645
    wCursorSizeAll = 32646
    wCursorNo = 32648
    wCursorHand = 32649
    wCursorAppStarting = 32650
    wCursorHelp = 32651

type
  wCursorError* = object of wGdiObjectError
    ## An error raised when wCursor creation failure.

proc error(self: wCursor) {.inline.} =
  raise newException(wCursorError, "wCursor creation failure")

proc isNilCursor(self: wCursor): bool {.inline.} =
  result = self.mHandle == 0

proc isCustomCursor(self: wCursor): bool {.inline.} =
  result = self.mHandle != -1 and self.mHandle != 0

proc getHotspot*(self: wCursor): wPoint {.validate, property.} =
  ## Returns the coordinates of the cursor hotspot.
  result = self.mHotspot

proc getSize*(self: wCursor): wSize {.validate, property.} =
  ## Returns the size of the cursor.
  result = (self.mWidth, self.mHeight)

proc getWidth*(self: wCursor): int {.validate, property, inline.} =
  ## Gets the width of the cursor in pixels.
  result = self.mWidth

proc getHeight*(self: wCursor): int {.validate, property, inline.} =
  ## Gets the height of the cursor in pixels.
  result = self.mHeight

method delete*(self: wCursor) =
  ## Nim's garbage collector will delete this object by default.
  ## However, sometimes you maybe want do that by yourself.
  if self.mHandle != 0 and self.mDeletable:
    if self.mIconResource:
      DestroyIcon(self.mHandle)
    else:
      DestroyCursor(self.mHandle)

  self.mHandle = 0

proc final*(self: wCursor) =
  ## Default finalizer for wCursor.
  self.delete()

proc init*(self: wCursor, hCursor: HCURSOR, copy = true, shared = false,
    hotspot = wDefaultPoint) {.validate.} =
  ## Initializer.
  self.wGdiObject.init()

  if hCursor == 0 or hCursor == -1: # wNilCursor or wDefaultCursor
    self.mWidth = wDefault
    self.mHeight = wDefault
    self.mHotspot = wDefaultPoint
    self.mHandle = hCursor
    self.mDeletable = false

  else:
    var iconInfo: ICONINFO
    if GetIconInfo(hCursor, iconInfo) != 0:
      defer:
        DeleteObject(iconInfo.hbmColor)
        DeleteObject(iconInfo.hbmMask)

      iconInfo.fIcon = FALSE
      if hotspot == wDefaultPoint:
        self.mHotspot = (int iconInfo.xHotspot, int iconInfo.yHotspot)
      else:
        iconInfo.xHotspot = hotspot.x
        iconInfo.yHotspot = hotspot.y
        self.mHotspot = hotspot

      (self.mWidth, self.mHeight) = iconInfo.getSize()

      if copy:
        self.mHandle = CreateIconIndirect(iconInfo)
        self.mIconResource = true
        self.mDeletable = true
      else:
        self.mHandle = hCursor
        self.mDeletable = not shared

    if self.mHandle == 0: self.error()

proc Cursor*(hCursor: HCURSOR, copy = true, shared = false,
    hotspot = wDefaultPoint): wCursor {.inline.} =
  ## Creates a cursor from Windows cursor handle.
  ## If *copy* is false, this only wrap it to wCursor object. It means the
  ## handle will be destroyed by wCursor when it is destroyed. So if you wrap a
  ## shared cursor handle into wCursor, you must set *shared* = true to avoid
  ## the handle being destroyed.
  new(result, final)
  result.init(hCursor, copy, shared, hotspot)

proc init*(self: wCursor, id: wStockCursor) {.validate.} =
  ## Initializer.
  self.wGdiObject.init()

  var hCursor = LoadCursor(0, MAKEINTRESOURCE(int id))
  if hCursor != 0:
    # MSDN: LoadCursor return a shared cursor, do not destroy it.
    self.init(hCursor, copy=false, shared=true)

  else: self.error()

proc Cursor*(id: wStockCursor): wCursor {.inline.} =
  ## Creates a cursor using a cursor identifier.
  new(result, final)
  result.init(id)

proc init*(self: wCursor, iconImage: wIconImage, size = wDefaultSize,
    hotspot = wDefaultPoint) {.validate.} =
  ## Initializer.
  wValidate(iconImage)
  self.wGdiObject.init()

  try:
    var
      newIconImage = IconImage(iconImage)
      width = if size.width < 0: iconImage.getWidth() else: size.width
      height = if size.height < 0: iconImage.getHeight() else: size.height
      hotspot = if hotspot == wDefaultPoint: iconImage.getHotspot() else: hotspot

    if hotspot == wDefaultPoint: self.error()

    newIconImage.toBmp()
    var
      buffer = newString(newIconImage.mIcon.len + 4)
      hotspotPtr = cast[ptr UncheckedArray[int16]](&buffer)

    hotspotPtr[0] = int16 hotspot.x
    hotspotPtr[1] = int16 hotspot.y
    copyMem(&hotspotPtr[2], &newIconImage.mIcon, newIconImage.mIcon.len)

    self.mHandle = CreateIconFromResourceEx(cast[PBYTE](&buffer), buffer.len,
      FALSE, 0x30000, width, height, 0)

    if self.mHandle == 0: self.error()
    (self.mWidth, self.mHeight, self.mHotspot) = (width, height, hotspot)
    self.mDeletable = true
    self.mIconResource = true

  except wError:
    self.error()

proc Cursor*(iconImage: wIconImage, size = wDefaultSize,
    hotspot = wDefaultPoint): wCursor {.inline.} =
  ## Creates a cursor from an icon image. If *hotspot* is wDefaultPoint, it use
  ## the hotspot stored in wIconImage object. If it is wDefaultPoint too, the
  ## creation failure.
  wValidate(iconImage)
  new(result, final)
  result.init(iconImage, size, hotspot)

proc init*(self: wCursor, icon: wIcon, hotspot: wPoint) {.validate, inline.} =
  ## Initializer.
  wValidate(icon)
  self.init(icon.mHandle, copy=true, hotspot=hotspot)

proc Cursor*(icon: wIcon, hotspot: wPoint): wCursor {.inline.} =
  ## Creates a cursor from the given wIcon object and hotspot.
  wValidate(icon)
  new(result, final)
  result.init(icon, hotspot)

proc init*(self: wCursor, image: wImage, hotspot: wPoint) {.validate, inline.} =
  ## Initializer.
  wValidate(image)
  try:
    self.init(IconImage(image), hotspot=hotspot)
  except wError:
    self.error()

proc Cursor*(image: wImage, hotspot: wPoint): wCursor {.inline.} =
  ## Creates a cursor from the given wImage object and hotspot.
  wValidate(image)
  new(result, final)
  result.init(image, hotspot)

proc init*(self: wCursor, bmp: wBitmap, hotspot: wPoint) {.validate, inline.} =
  ## Initializer.
  wValidate(bmp)
  try:
    self.init(IconImage(bmp), hotspot=hotspot)
  except wError:
    self.error()

proc Cursor*(bmp: wBitmap, hotspot: wPoint): wCursor {.inline.} =
  ## Creates a cursor from the given wBitmap object and hotspot.
  wValidate(bmp)
  new(result, final)
  result.init(bmp, hotspot)

proc init*(self: wCursor, cursor: wCursor, hotspot = wDefaultPoint) {.validate, inline.} =
  ## Initializer.
  wValidate(cursor)
  self.init(cursor.mHandle, copy=true, hotspot=hotspot)

proc Cursor*(cursor: wCursor, hotspot = wDefaultPoint): wCursor {.inline.} =
  ## Copy constructor. Hotspot can be changed if needed.
  wValidate(cursor)
  new(result, final)
  result.init(cursor, hotspot)

proc init*(self: wCursor, data: pointer, length: int, size = wDefaultSize,
    hotspot = wDefaultPoint) {.validate.} =
  ## Initializer.
  wValidate(data)

  try:
    # IconImage already has .ico or .cur format support.
    self.init(IconImage(data, length, size), size=size, hotspot=hotspot)

  except wIconImageError:
    # Add extra .ani format support.
    self.wGdiObject.init()
    let
      width = if size.width < 0: GetSystemMetrics(SM_CXCURSOR) else: size.width
      height = if size.height < 0: GetSystemMetrics(SM_CYCURSOR) else: size.height

    if length >= sizeof(int32) and cast[ptr int32](data)[] == 0x46464952: # .ani format
      var hCursor = CreateIconFromResourceEx(cast[PBYTE](data), length,
        FALSE, 0x30000, width, height, 0)

      if hCursor == 0: self.error()
      self.init(hCursor, copy=false, shared=false, hotspot=hotspot)

  finally:
    if self.mHandle == 0: self.error()

proc Cursor*(data: pointer, length: int, size = wDefaultSize,
    hotspot = wDefaultPoint): wCursor {.inline.} =
  ## Creates a cursor from binary data of .ico, .cur, or .ani file.
  wValidate(data)
  new(result, final)
  result.init(data, length, size, hotspot)

proc init*(self: wCursor, str: string, size = wDefaultSize,
    hotspot = wDefaultPoint) {.validate.} =
  ## Initializer.
  wValidate(str)

  try:
    # IconImage already has PE files, .ico/.cur format support.
    self.init(IconImage(str, size), size=size, hotspot=hotspot)

  except wIconImageError:
    # Add extra .ani format support.
    self.wGdiObject.init()
    try:
      var data = readFile(str)
      self.init(&data, data.len, size, hotspot)
    except: discard

  finally:
    if self.mHandle == 0: self.error()

proc Cursor*(str: string, size = wDefaultSize, hotspot = wDefaultPoint): wCursor
    {.inline.} =
  ## Creates a cursor from a file. The file should be in format of .ico, .cur,
  ## .ani, or Windows PE file (.exe or .dll, etc). If str is not a valid file
  ## path, it will be regarded as the binary data of .ico, .cur, or .ani file.
  ##
  ## For Windows PE file (.exe or .dll), it allows string like
  ## "shell32.dll,-10" to specifies the icon index or "shell32.dll:-1001" to
  ## to specifies the cursor index. Use zero-based index to specified the
  ## resource position, and negative value to specified the resource identifier.
  ## Empty filename (e.g. ",-1") to specified the current executable file.
  wValidate(str)
  new(result, final)
  result.init(str, size, hotspot)
