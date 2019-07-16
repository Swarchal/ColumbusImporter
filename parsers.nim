# stdlib modules
import strutils
import os
import tables

# ColumbusImporter modules
import parserUtils
import types
import wellutils


proc findPlatesizeYoko*(directory: string): tuple[err: int, size: string] =
  const accepted_plates = [96, 384, 1536]
  var
    wpp_text, field: string
    split_text: seq[string]
    error_code = 1
    rows, cols, plate_size: int
  for file in walkFiles(directory/"*.wpp"):
    # parse file for plate size
    wpp_text = readFile(file)
    split_text = wpp_text.splitWhitespace()
    for field in split_text:
      if field.startswith("bts:Columns="):
        cols = field.split("\"")[^2].parseInt
      if field.startswith("bts:Rows="):
        rows = field.split("\"")[^2].parseInt
    plate_size = rows*cols
    if accepted_plates.contains(plate_size):
      error_code = 0
  # otherwise failed to find the file or parse it correctly
  return (error_code, plate_size.intToStr)


proc findImageResolutionYoko*(directory: string): tuple[err: int, res: string] =
  const
    measurement_file = "MeasurementDetail.mrf"
  var
    error_code = 1
    image_resolution: string
    mrf_text: string
  try:
    mrf_text = readFile(directory/measurement_file)
    for field in mrf_text.splitWhitespace():
      if field.startswith("bts:HorizontalPixelDimension="):
        image_resolution = field.split("\"")[^2]
        error_code = 0
        break
  except IOError:
    return (error_code, image_resolution)
  return (error_code, image_resolution)

proc parsePath(path: Yokogawa): tuple[err:int, data:ParsedData] =
  # non-regex version to avoid PCRE issues
  var
    error_code : int
    parsed_data: ParsedData
    metadata   : string
    timepoint  : string
    field      : string
    plane      : string
    channel    : string
    well_name  : string
    row_name   : string
    column_name: string
    split_path = path.string.split("_")
  try:
    well_name = split_path[^2]
    row_name = well_name.row.intToStr
    column_name = well_name.column.intToStr
      # get the full metadata string without the file extension
    metadata  = split_path[^1].split(".")[0]
    # hard-coded indexing to get the metadata for each field without regex
    timepoint = metadata[1 .. 4]
    field     = metadata[6 .. 8]
    plane     = metadata[16 .. 17]
    channel   = metadata[19 .. 20]
    parsed_data = (wellname, row_name, column_name, timepoint,
                  field, plane, channel, path.string)
    error_code = 0
  except IndexError:
    # not a valid filepath, probably another file, so return empty parsed_data
    # and an error code
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


proc parsePath(path: Columbus): tuple[err: int, data: ParsedData] =
  var
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


proc parsePath(path: Harmony): tuple[err: int, data: ParsedData] =
  var
    error_code = 1
    parsed_data = ("", "", "", "", "", "", "", "")
  return (error_code, parsed_data)


proc parsePath(path:Incucyte): tuple[err: int, data: ParsedData] =
  var
    error_code: int
    parsed_data: ParsedData
    well_name: string
    row_name: string
    column_name: string
    field: string
    split_path = path.string.split("_")
    # these can't be parsed from the incucyte filename
    # timepoint will be replaced by the index of the ordered filenames
    timepoint = "replace_me"
    plane = "1" # incucyte only does a single z-plane (AFAIK)
    channel = "channel" # this will have to be changed by the user
  try:
    echo split_path
    well_name = split_path[^4]
    row_name = well_name.row.intToStr
    column_name = well_name.column.intToStr
    field = split_path[^3]
    parsed_data = (well_name, row_name, column_name, timepoint, field, plane,
                   channel, path.string)
  except IndexError:
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
