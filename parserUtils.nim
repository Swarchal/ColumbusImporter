# stdlib modules
import os
import nre
import tables
import algorithm
import sequtils
import strutils

# ColumbusImporter modules
import types


const
  Extensions = [".tif", ".tiff"]


func toTable*(data: ParsedData): Table[string, string] =
  var output_table = initTable[string, string]()
  for key, value in data.fieldPairs:
    output_table[key] = value
  return output_table


func fieldNames*(data: ParsedData): seq[string] =
  for i, j in data.fieldPairs:
    result.add(i)


func isImage*(img_path: string): bool =
  # determines if a path is an image by it's file extension
  for ext in Extensions:
    if img_path.endsWith(ext):
      return true
  return false


func getAllImages*(directory: string): seq[string] =
  # get all images in a directory
  for _, file in walkDir(directory):
    if file.isImage:
      result.add(file)


proc toImageGroup(x: ParsedData): ImageGroup =
  return (x.Wellname, x.Field)


proc groupAndSort*(captures: seq[ParsedData]): seq[seq[ParsedData]] =
  #[
    Group ParsedData by WellName and Field, and then sort each well/field group
    by their sourcefilename, which when sorted alphabetically should be in
    time order.
  ]#
  var
    image_tab = initTable[ImageGroup, seq[ParsedData]]()
    group: ImageGroup
  for data in captures:
    group = data.toImageGroup
    if image_tab.contains(group):
      # group is already in the table, so append to the sequence
      image_tab[group].add(data)
    else:
      # group not in the table, to create a new key and start the sequence
      image_tab[group] = @[data]
  # now we have a table of filepaths, need to sort each group
  for key, value in image_tab.pairs:
    # sorting by sourcefilename *should* sort by timestamp
    result.add(value.sortedByIt(it.sourcefilename))


proc addTimePoint*(grouped: seq[seq[ParsedData]]): seq[ParsedData] =
  #[
    Go through a grouped (and sorted) ParsedData and assign a new TimePoint,
    which is just the index of the ordered seq.
  ]#
  var
    tmp_data: ParsedData
  for group in grouped:
    for index, indv in group.pairs:
      tmp_data = indv
      tmp_data.Timepoint = $(index + 1)
      result.add(tmp_data)

