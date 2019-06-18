# stdlib modules
import strutils
import os
import tables
import nre

# ColumbusImporter modules
import parserUtils
import types
import wellutils


func toParsedData(regex_tab: Table, sourceFileName: string): ParsedData =
  # convert a regex table to a ParsedData type
  var
    output: ParsedData
  output = (
    regex_tab["WellName"],
    regex_tab["WellName"].row.intToStr,
    regex_tab["WellName"].column.intToStr,
    regex_tab["Timepoint"],
    regex_tab["Field"],
    regex_tab["Plane"],
    regex_tab["Channel"],
    sourceFileName
  )
  return output


proc findPlateSizeYoko*(directory: string): tuple[err: int, size: string] =
  # Try and identify the plate size from the XML metadata present
  const accepted_plates = [96, 384, 1536]
  var
    wpp_text: string
    rows, cols, error_code, plate_size: int
  for file in walkFiles(directory/"*.wpp"):
    # parse file for plate size
    wpp_text = readFile(file)
    var
      col_regex = wpp_text.find(re("(?<=bts:Columns=\")\\d+"))
      row_regex = wpp_text.find(re("(?<=bts:Rows=\")\\d+"))
    # check if successfully parsed
    # if so, calculates plate size from row and column values
    if col_regex.isSome and row_regex.isSome:
      let
        cols = col_regex.get.captures[-1].parseInt
        rows = row_regex.get.captures[-1].parseInt
      plate_size = rows * cols
      if accepted_plates.contains(plate_size):
        error_code = 0
        return (error_code, plate_size.intToStr)
  # otherwise failed to find the file or parse it correctly
  error_code = 1
  return (error_code, plate_size.intToStr)


proc findImageResolutionYoko*(directory: string): tuple[err: int, res: string] =
  const
    measurement_file = "MeasurementDetail.mrf"
  var
    error_code = 1
    image_resolution: string
    mrf_text: string
    regex_query = re(r"(?<=bts:HorizontalPixelDimension=.)\d+\.\d+")
  try:
    mrf_text = readFile(directory/measurement_file)
  except IOError:
    return (error_code, image_resolution)
  var
    regex_out = mrf_text.findAll(regex_query)
  if len(regex_out) > 0:
    # then there is a regex match
    image_resolution = regex_out[0]
    error_code = 0
  return (error_code, image_resolution)


proc parsePath(path: Yokogawa): tuple[err:int, data:ParsedData] =
  #[
    Parse a Yokogawa CV8000 filepath for metadata.
    The Yokogawa exports Metadata on plate-type and image resolution within
    the directory of the images, so these can be parsed from the the files
    if present and set as the initial values.
  ]#
  var
    error_code: int
    parsed_data: ParsedData
    regex_table: Table[string, string]
    regex_str = re(
      r"(?<WellName>[A-Z]{1}[0-9]{2})_" &
      r"T(?<Timepoint>[0-9]{4})" &
      r"F(?<Field>[0-9]{3})" &
      r"L(?<l>[0-9]{2})" & # what is L??
      r"A(?<a>[0-9]{2})" & # what is A??
      r"Z(?<Plane>[0-9]{2})" &
      r"C(?<Channel>[0-9]{2})."
    )
    regex_search = path.string.find(regex_str)
  try:
    regex_table = regex_search.get.captures.toTable()
    parsed_data = regex_table.toParsedData(path.string)
    error_code = 0
  except UnpackError:
    # toParseData() failed because the path is not a standard yoko image path.
    # return ParsedData with empty strings as values and an error code
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


proc parsePath(path: Columbus): tuple[err:int, data:ParsedData] =
  var
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


proc parsePath(path: Harmony): tuple[err:int, data:ParsedData] =
  var
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


proc parsePath(path: Incucyte): tuple[err:int, data:ParsedData] =
  #[
    The incucyte exports a directory per channel, so it is not possible to
    parse the channel information out of the filename, and it will be up
    to the user to change the channel column in the .csv file.
    A message should be shown when saving with the Incucyte parser that
    the channel needs to be changed per csv file. As there are no guarantees
    that the information will be in the directory name in any reliable format.
  ]#
  var
    error_code: int
    parsed_data: ParsedData
    regex_str = re(
      r"(?<Exp>[a-zA-Z0-9]+)_" &
      r"(?<WellName>[A-Z]{1}[0-9]*)_" &
      r"(?<Field>[0-9]*)_" &
      r"(?<Year>[0-9]{4})y" &
      r"(?<Month>[0-9]*)m" &
      r"(?<Day>[0-9]*)d_" &
      r"(?<Hour>[0-9]*)h" &
      r"(?<Minute>[0-9]*)m"
    )
    regex_search = path.string.find(regex_str)
  try:
    var regex_table = regex_search.get.captures.toTable()
    # as we have not parsed a TimePoint yet, but it's needed by toParsedData()
    # add a dummy TimePoint value into the table before passing to toParsedData
    regex_table["Timepoint"] = "replace_me"
    # incucyte only captures in one plane / Z-position (afaik)
    regex_table["Plane"] = "1"
    # add in dummy channel as this can't be parsed automatically
    regex_table["Channel"] = "channel"
    # contains all the necessary keys, convert table to ParsedData
    parsed_data = regex_table.toParsedData(path.string)
    error_code = 0
  except UnpackError:
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)



proc parsePath(path: Zeiss): tuple[err:int, data:ParsedData] =
  var
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


# TODO: get rid of these horrible dispatcher procedures
# need to find a way to handle multiple-dispatch in nim properly
proc parseDirectory_t(directory: string, parser: typedesc): seq[ParsedData] =
  var
    err: int
    data: ParsedData
    output: seq[ParsedData]
  for img_path in getAllImages(directory):
    (err, data) = parsePath(parser(img_path))
    if err != 1:
      output.add(data)
  if parser is Incucyte:
    output = output.groupAndSort.addTimePoint()
  assert len(output) > 0
  return output


# TODO: get rid of these horrible dispatcher procedures
# need to find a way to handle multiple-dispatch in nim properly
proc parseDirectory*(directory: string, parser: string): seq[ParsedData] =
  #[
    since I can't figure out how to pass Types round as variables or store
    them within Tables, this function will have to accept a string as an input
    and then use the function with the typedesc already set.
  ]#
  let
    parser = parser.toLower()
  case parser:
    of "yokogawa":
      result = parseDirectory_t(directory, Yokogawa)
    of "columbus":
      result = parseDirectory_t(directory, Columbus)
    of "harmony":
      result = parseDirectory_t(directory, Harmony)
    of "incucyte":
      result = parseDirectory_t(directory, Incucyte)
    of "zeiss":
      result = parseDirectory_t(directory, Zeiss)
    else:
      # return an empty seq
      result = @[]
