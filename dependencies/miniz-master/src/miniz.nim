{.compile: "miniz.c".}

proc mz_compressBound*(source_len: int64): int64 {.importc: "mz_compressBound".}
proc mz_compress2(pDest: cstring, pDest_len: ptr int64, pSource: cstring, source_len: int64, level: cint): cint {.importc: "mz_compress2".}
proc mz_uncompress(pDest: cstring, pDest_len: ptr int64, pSource: cstring, source_len: int64): cint {.importc: "mz_uncompress".}


proc compress*(src: string, level: int = 6): string =
  ## Compresses string with level
  var maxLenOut = mz_compressBound(src.len)
  result = newString(maxLenOut)
  var compressedSize: int64 = maxLenOut
  var status = mz_compress2(result, addr compressedSize, cstring src, src.len, cint(level))
  assert status == 0
  result.setLen(compressedSize)


proc uncompress*(zsrc: string): string =
  ## Decompresses a string
  var maxLenOut = zsrc.len * 1000
  result = newString(maxLenOut)
  var uncompressedSize: int64 = maxLenOut
  var status = mz_uncompress(result, addr uncompressedSize, zsrc, zsrc.len)
  assert status == 0
  result.setLen(uncompressedSize)
