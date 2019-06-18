Version 3.1
-----------
* Add wincred module.

Version 3.0
-----------
* Add winimx tool to generate the minified winim module.
* Add -d:noRes to disable the visual styles.
* Don't maintain compatibility with Nim Compiler 0.18 anymore.
* Remove -d:useWinXP (useless under Nim Compiler >= 0.19).

Version 2.6.1
-------------
* Update for Nim Compiler 0.19.9 again.
* Remove -d:mshtml (not so useful)
* Small change for new winimx tool.

Version 2.6
-----------
* Update for Nim Compiler 0.19.9.
* Add wincodec module.

Version 2.5.2
-------------
* commctrl: add "commoncontrols.h".

Version 2.5.1
-------------
* Update for Nim Compiler 0.19.

Version 2.5
-----------
* winstr: Fix nil issue for string in devel compiler. Now it won't
  allow nil for string anymore. This change maybe break the code
  if it has different behavior between nil and empty string.
* Add support to Tiny C Compiler. See readme in tcclib.

Version 2.4.4
-------------
* Fix bug about using sizeof() incorrectly.

Version 2.4.3
-------------
* com: call CoInitialize() only when needed. This allow the user to
  selects different apartment or OleInitialize().
* winbase: add InterlockedXXX functions.
* example: add nimDispatch example. It create a IDispatch object on
  local "running object table (ROT)". So that RPC via COM object is
  achieved.

Version 2.4.2
-------------
* winuser: fix bugs about MAKEINTRESOURCE template.
* commctrl: fix bugs about templates use NULL for handle (should be 0).

Version 2.4.1
-------------
* com: A critical bug about dot operator fixed.

Version 2.4
-----------
* Using '/' instead of '.' to import paths.
* com: Add `[]` and `[]=` to access com object.
* com: Add ability to access COM object constants.
* winstr: Add TString and TChar.

Version 2.3
-----------
* Add var version access proc for nested struct/union.
  It will be used in this situation:
    ```nimrod
    var insert: TVINSERTSTRUCT
    insert.item.mask = TVIF_TEXT or TVIF_PARAM
    ```
* Fix some literal constant with 'U' suffix.

Version 2.2
-----------
* Fix converter ambiguous problems.
* Add -d:useWinXP for Windows XP compatibility.

Version 2.1
-----------
* Ready for Nim compiler version 0.18.1.
* Remove some APIs that Windows 7 not supports to avoid
  "could not import" error message.

Version 2.0
-----------
* Ready for Nim compiler version 0.18.0.
* All windows API and constant definitions are translated from MinGW's
  headers files now. Not depends on "D WinAPI programming" anymore.
* API modules can import one by one if needed.
  Ex: import winim.inc.winuser
* Add lean module for import core Windows SDK only, mean module
  for core + Shell + OLE API.
  Use import winim.lean or -d:lean to switch.
* Add -d:useWinAnsi to use the Ansi versions of the Windows API.
* Add -d:mshtml or import winim.html or winim.inc.mshtml for MSHTML.
  (file size is too big, add only if needed.)
* Remove -d:winstyle (always enabled)
* winstr: add toHex, nullTerminate, nullTerminated, `<<<`, `>>>`,
  mlen, mIndex, etc. Also some fix some bug.
* com: add multithreads support.

Version 1.2.1
--------------
* winapi: add double quotes to resource file
* winapi: fix bug about GetWindowLongPtr and NMHDR etc.

Version 1.2
-----------
* winapi: redefine const to int literals if possible
* winapi: convert enum to const definition
* winapi: add more definition in shobjidl.h, propsys.h, shtypes.h,
  and structuredquerycondition.h
* com: better error message on COMError exception

Version 1.1
-----------
* winapi: add -d:winstyle to enable windows visual styles

Version 1.0
-----------
* Initial release
