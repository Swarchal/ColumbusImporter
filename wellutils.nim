import strutils


func charToInt(x: char): int =
  # 1-indexed character to integer conversion
  return ord(x.toLowerAscii) - 96


func row*(well: string): int =
  # get 1-indexed row index from well ID
  var rows: seq[int]
  for ch in well:
    if ch.isAlphaAscii:
      rows.add(ch.charToInt)
  # make this work with wells form a 1536 plate
  if rows.len > 1:
    return rows[1] + 26
  return rows[0]


func column*(well: string): int =
  # get 1-indexed column index from well ID
  var cols: seq[char]
  for ch in well:
    if ch.isDigit:
      cols.add(ch)
  return cols.join.parseInt


func parseWell*(well: string): tuple[row: int, column: int] =
  return (well.row, well.column)
