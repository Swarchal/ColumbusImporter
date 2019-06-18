# stdlib modules
import tables

type
  # type for each microscope platform so we can use multiple dispatch
  # to use the correct parsing methods (hopefully)
  Yokogawa* = distinct string
  Columbus* = distinct string
  Harmony*  = distinct string
  Incucyte* = distinct string
  Zeiss*    = distinct string

  # data type, common to all microscope platforms
  ParsedData* = tuple[
    WellName :      string,
    Row:            string,
    Column:         string,
    Timepoint:      string,
    Field:          string,
    Plane:          string,
    Channel:        string,
    sourcefilename: string,
  ]

  CSV* = seq[Table[string, string]]

  # used as a key type in Tables for grouping images by well and field
  ImageGroup* = tuple[
    well:  string,
    field: string
  ]
