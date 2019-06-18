# stdlib modules
import os
import ospaths

# ColumbusImporter modules
import types
import parsers
import csvwriter

# external modules
import wnim


const
  H_PAD = 5
  V_PAD = 15
  LARGE_V_PAD = 25

var
  app* = App()
  frame* = Frame(title="Columbus Importer", style=wDefaultFrameStyle)
  panel* = Panel(frame)

frame.size = (400, 540)
frame.minSize = (400, 540)

panel.margin = 10

################################################################################
# microscope selection
################################################################################
var
  microscope: string
  box_microscope = StaticBox(panel, label="Microscope")
  micro_button_yoko = RadioButton(panel, label="CV8000 (Yokogawa)")
  micro_button_columbus = RadioButton(panel, label="Columbus (PerkinElmer)")
  micro_button_harmony = RadioButton(panel, label="Harmony (PerkinElmer)")
  micro_button_incucyte = RadioButton(panel, label="Incucyte (Essen)")
  micro_button_ziess = RadioButton(panel, label="??? (Zeiss)")

micro_button_yoko.wEvent_RadioButton do():
  microscope = "Yokogawa"
  echo "INFO: setting microscope to: " & microscope
micro_button_columbus.wEvent_RadioButton do():
  microscope = "Columbus"
  echo "INFO: setting microscope to: " & microscope
micro_button_harmony.wEvent_RadioButton do():
  microscope = "Harmony"
  echo "INFO: setting microscope to: " & microscope
micro_button_incucyte.wEvent_RadioButton do():
  microscope = "Incucyte"
  echo "INFO: setting microscope to: " & microscope
micro_button_ziess.wEvent_RadioButton do():
  microscope = "Zeiss"
  echo "INFO: setting microscope to: " & microscope

################################################################################
# plate selection
################################################################################
var
  plate_size: string
  box_plate = StaticBox(panel, label="Plate size")
  plate_button_96 = RadioButton(panel, label="96")
  plate_button_384 = RadioButton(panel, label="384")
  plate_button_1536 = RadioButton(panel, label="1536")

plate_button_96.wEvent_RadioButton do():
  plate_size = "96"
  echo "INFO: plate size changed to: " & plate_size
plate_button_384.wEvent_RadioButton do():
  plate_size = "384"
  echo "INFO: plate size changed to: " & plate_size
plate_button_1536.wEvent_RadioButton do():
  plate_size = "1536"
  echo "INFO: plate size changed to: " & plate_size

################################################################################
# image resolution text box
################################################################################
var
  image_resolution: string
  box_resolution = StaticBox(panel, label="Image resolution")
  resolution_text_box = TextCtrl(panel, value="0.0", style=wBorderSunken)

resolution_text_box.wEvent_TextEnter do():
  image_resolution = resolution_text_box.label
  echo "INFO: image resolution changed to: " & image_resolution

################################################################################
# directory picker
################################################################################
var
  directory_path: string
  plate_err_code: int
  res_err_code: int
  box_directory_picker = StaticBox(panel, label="Image Directory")
  directory_text_box = TextCtrl(panel, style=wBorderSunken)
  directory_button = Button(panel, label="...")
  directory_dialog = DirDialog(frame, style=wDdDirMustExist)
  invalid_dir_message = MessageDialog(
    panel, style=wIconErr, message="directory doesn't exist"
  )

# set directory from directory dialog
directory_button.wEvent_Button do():
  if directory_dialog.show() == wIdOk:
    directory_path = directory_dialog.path
    directory_text_box.label = directory_path
    echo "INFO: input directory set from dialog to: " & directory_path
    # try and find plate size from metadata within directory
    case microscope:
      of "Yokogawa":
        (plate_err_code, plate_size) = findPlateSizeYoko(directory_path)
        (res_err_code, image_resolution) = findImageResolutionYoko(directory_path)
      of "Incucyte":
        echo "INFO: incucyte testing ..."
      else:
        # need to make other microscope plate file sizers
        raise newException(ValueError, "not made this parser yet")
    if plate_err_code != 1:
      # need to set non-active plate sizes to `false` as it's possible to have
      # more than one radioButton active using .setValue
      case plate_size:
        of "96":
          plate_button_96.setValue(true)
          plate_button_384.setValue(false)
          plate_button_1536.setValue(false)
        of "384":
          plate_button_96.setValue(false)
          plate_button_384.setValue(true)
          plate_button_1536.setValue(false)
        of "1536":
          plate_button_96.setValue(false)
          plate_button_384.setValue(false)
          plate_button_1536.setValue(true)
    # try and find the image resolution from metadata within directory
    if res_err_code != 1:
      resolution_text_box.label = image_resolution


# set directory from entering text
################################################################################
# TODO: update once focus moves away from text box
################################################################################
directory_text_box.wEvent_TextEnter do():
  directory_path = directory_text_box.label
  if directory_path.dirExists:
    echo "INFO: directory exists"
      # try and find plate size from metadata within directory
    case microscope:
      of "Yokogawa":
        (plate_err_code, plate_size) = findPlateSizeYoko(directory_path)
        (res_err_code, image_resolution) = findImageResolutionYoko(directory_path)
      of "Incucyte":
        echo "INFO: incucyte testing ..."
        # TODO: try and parse the image resolution from the image metadata
      else:
        # need to make other microscope plate file sizers
        raise newException(ValueError, "not made this parser yet")
    if plate_err_code != 1:
      case plate_size:
        of "96":
          plate_button_96.setValue(true)
          plate_button_384.setValue(false)
          plate_button_1536.setValue(false)
        of "384":
          plate_button_96.setValue(false)
          plate_button_384.setValue(true)
          plate_button_1536.setValue(false)
        of "1536":
          plate_button_96.setValue(false)
          plate_button_384.setValue(false)
          plate_button_1536.setValue(true)
    # try and find the image resolution from metadata within directory
    if res_err_code != 1:
      resolution_text_box.label = image_resolution
  else:
    invalid_dir_message.show()
    echo "WARNING: directory doesn't exist"
  echo "INFO: input directory set from text to: " & directory_path
# TODO: set directory from drag and drop into text box



################################################################################
# create csv button
################################################################################
# cannot set deault filename in Wx on windows, so just have the user
# choose the directory and save as ${directory}/ImageIndex.ColumbusIDX.csv
# As the CSV file *has* to be named in a certain way for columbus to find it.
var
  save_path: string
  parsed_data: seq[ParsedData]
  csv_file: CSV
  box_create_table = StaticBox(
    panel, label="Create import file (save file in this directory)"
  )
  button_create_table = Button(panel, label="Save")
  output_dialog = DirDialog(frame, style=wDdDirMustExist)
  saved_dialog = MessageDialog(
    panel, message="File saved"
  )

const
  output_name = "ImageIndex.ColumbusIDX.csv"

button_create_table.wEvent_Button do():
  if output_dialog.show() == wIdOk:
    save_path = output_dialog.path/output_name
    parsed_data = parseDirectory(directory_path, microscope)
    csv_file = parsed_data.toCSV()
    # have to sortRows before adding new columns, as sorting rows reverts
    # the csv object back to ParsedData which does not contain the fields
    # for ImageResolution* or Plate
    csv_file = csv_file.sortRows()
    csv_file = csv_file.addColumn("ImageResolutionX@um", image_resolution)
    csv_file = csv_file.addColumn("ImageResolutionY@um", image_resolution)
    csv_file = csv_file.addColumn("Plate", plate_size)
    csv_file.writeCSV(path=save_path)
    # TODO: check file has actually been saved successfully
    saved_dialog.setMessage("File saved at: " & save_path)
    saved_dialog.show()



################################################################################
# GUI layout
################################################################################
proc layout*() =
  panel.layout:
    ############################################################################
    # microscope selection
    ############################################################################
    box_microscope:
      top = panel.top
      bottom = micro_button_ziess.bottom + V_PAD
      left = panel.left
      right = panel.right

    micro_button_yoko:
      top = box_microscope.top + LARGE_V_PAD
      left = box_microscope.innerLeft + H_PAD
      right = box_microscope.innerRight - H_PAD
      height = V_PAD

    micro_button_columbus:
      top = micro_button_yoko.bottom + H_PAD
      left = box_microscope.innerLeft + H_PAD
      right = box_microscope.innerRight - H_PAD
      height = V_PAD

    micro_button_harmony:
      top = micro_button_columbus.bottom + H_PAD
      left = box_microscope.innerLeft + H_PAD
      right = box_microscope.innerRight - H_PAD
      height = V_PAD

    micro_button_incucyte:
      top = micro_button_harmony.bottom + H_PAD
      left = box_microscope.innerLeft + H_PAD
      right = box_microscope.innerRight - H_PAD
      height = V_PAD

    micro_button_ziess:
      top = micro_button_incucyte.bottom + H_PAD
      left = box_microscope.innerLeft + H_PAD
      right = box_microscope.innerRight - H_PAD
      height = V_PAD

    ############################################################################
    # directory picker
    ############################################################################
    box_directory_picker:
      top = box_microscope.bottom + V_PAD
      bottom = directory_text_box.bottom + V_PAD
      left = panel.left
      right = panel.right
    
    directory_text_box:
      top = box_directory_picker.top + LARGE_V_PAD
      height = LARGE_V_PAD
      left = box_directory_picker.innerLeft + H_PAD
      right = directory_button.left

    directory_button:
      top = box_directory_picker.top + LARGE_V_PAD
      height = LARGE_V_PAD
      right = panel.innerRight - H_PAD
      left = directory_text_box.right
      width = 30

    ############################################################################
    # plate selection
    ############################################################################
    box_plate:
      top = box_directory_picker.bottom + V_PAD
      bottom = plate_button_1536.bottom + V_PAD
      left = panel.left
      right = panel.right

    plate_button_96:
      top = box_plate.top + LARGE_V_PAD
      left = box_plate.innerLeft + H_PAD
      right = box_plate.innerRight - H_PAD
      height = V_PAD

    plate_button_384:
      top = plate_button_96.bottom + H_PAD
      left = box_plate.innerLeft + H_PAD
      right = box_plate.innerRight - H_PAD
      height = V_PAD

    plate_button_1536:
      top = plate_button_384.bottom + H_PAD
      left = box_plate.innerLeft + H_PAD
      right = box_plate.innerRight - H_PAD
      height = V_PAD

    ############################################################################
    # Image resolution text box
    ############################################################################
    box_resolution:
      top = box_plate.bottom + V_PAD
      bottom = resolution_text_box.bottom + V_PAD
      left = panel.left
      right = panel.right

    resolution_text_box:
      top = box_resolution.top + LARGE_V_PAD
      height = LARGE_V_PAD
      left = box_resolution.innerLeft + H_PAD
      right = box_resolution.innerRight - H_PAD

    ############################################################################
    # create csv button
    ############################################################################
    # button that opens a file dialog listing where to save the csv file
    box_create_table:
      top = box_resolution.bottom + V_PAD
      bottom = button_create_table.bottom + V_PAD
      left = panel.left
      width = panel.right

    button_create_table:
      top = box_create_table.top + LARGE_V_PAD
      height = LARGE_V_PAD
      left = box_create_table.innerLeft + H_PAD
      width = 50
