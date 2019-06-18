# stdlib modules
import algorithm
import sequtils
import strutils
import tables

# ColumbusImporter modules
import types
import parsers
import parserUtils


func addColumn*(csv: CSV, colname: string, coldata: string): CSV =
  # add column from a single string
  var
    tmp_table: Table[string, string]
  for entry in csv:
    tmp_table = entry
    tmp_table[colname] = coldata
    result.add(tmp_table)
  assert len(result) == len(csv)


func addColumn*(csv: CSV, colname: string, coldata: openArray[string]): CSV =
  # add column from a sequence of strings
  assert len(csv) == len(coldata)
  var
    tmp_table: Table[string, string]
  for index, entry in csv.pairs:
    tmp_table = entry
    tmp_table[colname] = coldata[index]
    result.add(tmp_table)
  return result


proc getHeader(csv: CSV): seq[string] =
  for key in csv[0].keys:
    result.add(key)


func makeRow(entry: Table[string, string]): seq[string] =
  for value in entry.values:
    result.add(value)


func toString*(csv: CSV, sep="\t", newline="\n"): string =
  # convert CSV type to a string which can be saved to a file
  var
    row_seq: seq[string]
    row: string
  let
    header = csv.getHeader.join(sep)
  row_seq.add(header)
  # add each row
  for entry in csv:
    row = entry.makeRow.join(sep)
    row_seq.add(row)
  return row_seq.join(newline)


proc toCSV*(parsed: seq[ParsedData]): CSV =
  # create a csv from the output of parsers.parseDirectory
  var
    output: CSV
  for entry in parsed:
    output.add(entry.toTable)
  return output


proc toParsedData(table: Table[string, string]): ParsedData =
  # convert an entry in CSV (Table[string, string]) to a ParsedData type
  var
    output: ParsedData
  output = (
    WellName:       table["WellName"],
    Row:            table["Row"],
    Column:         table["Column"],
    Timepoint:      table["Timepoint"],
    Field:          table["Field"],
    Plane:          table["Plane"],
    Channel:        table["Channel"],
    sourcefilename: table["sourcefilename"]
  )
  return output


proc toParsedData(csv: CSV): seq[ParsedData] =
  # convert CSV to ParsedData
  for table in csv:
    result.add(toParsedData(table))


proc sortRows*(csv: CSV,): CSV =
  # sort rows of dataframe based on the values in multiple columns.
  # columns: [WellName, Row, Column, Field, Channel, Plane]
  # Not necessary but otherwise the csv file is in an unexpected order.
  var
    tmp_table: Table[string, string]
    parseddata_seq: seq[ParsedData]
  # convert CSV format to ParsedData
  parseddata_seq = csv.toParsedData()
  # sort sequence by columns
  parseddata_seq = parseddata_seq.sortedByIt(
    (it.WellName, it.Row, it.Column, it.Field, it.Channel, it.Plane)
  )
  # convert back to CSV format
  return parseddata_seq.toCSV()


func shape*(csv: CSV): array[2, int] =
  # shape of the csv object (rows, columns)
  # NOTE: assumes all tables in the CSV have the same number of entries
  let
    rows = len(csv)
    cols = len(csv[0])
  return [rows, cols]


func validateCSV(csv: CSV): bool =
  # assert all rows have the same number of columns
  # in this case it's all tables in the seq have the same number of entries
  let
    first_size = len(csv[0])
  for entry in csv:
    if len(entry) != first_size:
      return false
  return true


proc writeCSV*(csv: CSV, path: string, sep="\t", newline="\n") =
  let
    csv_str = csv.toString(sep, newline)
  writeFile(path, csv_str)
