# SKY130 Workflow RTL-with-Custom-Standardcell to GDSII-Macrocell

**Initial version by Manuel Moser,
update by Harald Pretl.**

If you want RTL mixed with predefined standard cells (including custom cells), synthesized, and converted to a GDSII macro while the workflow is not allowed to "optimize" the structure, then this guide is for you.

This documentation was written using the SKY130 [iic-osic-tools](https://github.com/iic-jku/iic-osic-tools) design environment and is sponsored by lots of coffee.

![workflow](images/Flow.png "Workflow")

## Magic: Design of a custom standard cell

Making custom standard cells is pretty difficult. You have to make sure that your standard cells boundary-box abuts all other standard cells in all orientations without generating DRC errors. Keep an eye on your log files, especially the DRC and manufacturability logs, and double-check your results.

In the end, the standard cell should look somewhat like this:

![Result](images/buf8.png "8 stage buffer")

### Workaround for falsely-expected macros

UPDATE: MPL-0004 has been changed to a warning, which means the workaround should not be needed after an [update of OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD/commit/b84718ffe1ac04a0df1697e1e0e7339eb5414de0).

Openlane expects macros if a LEF file is added to the design, which is the wrong behavior in our case since we are adding a custom standard cell. Macros are handled differently from standard cells in terms of placement and power distribution. Standard cells are placed inside a horizontal power grid on `metal1` after the PDN on `metal1` and `metal4` have been generated and routed. The result is a hardened macro. Macros should, therefore, already have a vertical PDN on `metal4`; they should be connected to the horizontal PDN on `metal5` later. Until an official solution is out, disable `basic_macro_placement` in `/foss/tools/openlane/*/scripts/tcl_commands/floorplan.tcl` as suggested in the Slack channel.

Maybe you need root access for this workaround. Start the docker-container with user `0` and group `0`. If you're using `iic-osic-tools`, you may edit the start_vnc script.

```shell
docker run -d --user 0:0 %PARAMS% -v "%DESIGNS%":/foss/designs  %DOCKER_USER%/%DOCKER_IMAGE%:%DOCKER_TAG%
```

### Cell layout

Read this first: [Design rules](https://github.com/nickson-jose/vsdstdcelldesign)  

### Port alignment

For place & route, all ports should be aligned on the crosssections of a grid. To show the grid for high-density cells (`sky130_fd_sc_hd__...`) type `grid 0.46um 0.34um 0.23um 0.17um` into the magic TCL-console. Adapt the grid if you work with a different standard cell from **`_hd_`**.

### Cell size

Property `FIXED_BBOX` needs to be set; this value is used to align multiple standard cells next to each other; the bounding boxes should not overlap in all directions!

X and Y dimensions must equal multiples of a constant value - [see PDK Documentation](https://antmicro-skywater-pdk-docs.readthedocs.io/en/latest/contents/libraries/foundry-provided.html) for X-Grid and Y-Grid.

For a high-density custom cell, the size in micrometers is $(N \cdot 0.46) \times (8 \cdot 0.34)$. Scale the result to your Magic internal value (lambda). In our case, a multiplication by 200 is needed since the internal lambda-grid is 0.005um, so for $h = 2.72\,\mu m$ and $w = 9.66\,\mu m$ the proper value for our design environment would be `property FIXED_BBOX {0 0 1932 544}`.

The PDK high-density standard cell Magic-files are located in `$PDKPATH/libs.ref/sky130_fd_sc_hd/mag/..`. You may want to compare them to your design.

### Tap connections

Notice that most standard cells don't have tap (=well) connections (which is the case in a tap-less standard cell library); instead, there is a port `VNB` on `pwell` and `VPB` on `nwell`. The tap connections are placed as tap-standard cells with a defined distance (the tap distance).

### Placement of poly connectors

If you look at other standard cells, you may notice it is good practice to place poly-connectors only in the middle area of the standard cell.

### Port definition

Select the area where you want a port connection, then select `Edit` and `Text..` in Magic. Enter the name of the port in `Text`-string, check `sticky`, uncheck `default`, enter the layer where the port should be (`li1`, `metal1`, etc.), set the size to 0.1um, check `Port enable`, and choose connection orientations (`n`, `s`, `e`, `w`, `center`, ...).

The auto-router needs to know some additional properties of your ports. Set the following properties in the Magic TCL-console for each port:

`VPWR` and `VPB` (PMOS bias):

```tcl
port use power
port class inout
port shape abutment
```

`VGND` and `VNB` (PMOS bias):

```tcl
port use ground
port class inout
port shape abutment
```

Any input signals:

```tcl
port use signal
port class input
```

Any output signals:

```tcl
port use signal
port class output
```

### LEF file options

Enter in the Magic TCL-console:

```tcl
property LEFclass CORE
property LEFsource USER
property LEFsite unithd
property LEForigin {0 0}
```

### Generate LEF and GDS file

Type in the Magic TCL-console:

```tcl
lef write
gds
```

We suggest copying the LEF and GDS file to your OpenLane design `src` directory.

### Generate LIB file

Use the `tt` library file from `$PDKPATH/libs.ref/sky130_fd_sc_<TYPE>/lib/` as a template for custom lib-files. The resulting file should contain the header and a definition for the custom standard-cells `cell ("name_of_your_cell") { ... }`. Copy the file to `/foss/designs/<PROJECT-NAME>/openlane/<CELL-NAME>/src`.  

Note: The timing and power tables do not contain correct data in this example. Instead, we have copied the data from a different cell and ditched updating the copied tables. The flow will still run through since we did not allow altering/optimizing the functional structure after synth in the `config.tcl` file. You can try to look into the `OpenROAD` command `write_timing_model` if the data in the liberty tables need to be updated, but this feature might be experimental.  

## OpenLane: RTL-to-GDSII config and workflow

Openlane synthesizes the RTL file with the custom cells treated as a black box. The synthesized file is then parsed for floorplan generation, placement, and routing.

### Config file

In the OpenLane config-file `../openlane/<CELL-NAME>/config.tcl`, add the following lines:

```tcl
# Include Custom Standardcells  
 set ::env(EXTRA_LEFS) [glob $::env(DESIGN_DIR)/src/*.lef]  
 set ::env(EXTRA_LIBS) [glob $::env(DESIGN_DIR)/src/*.lib]  
 set ::env(EXTRA_GDS_FILES) [glob $::env(DESIGN_DIR)/src/*.gds]  
 set ::env(SYNTH_READ_BLACKBOX_LIB) 1  
```

### Run OpenLane

Run `flow.tcl -design <DESIGN_NAME>` in `/foss/designs/<PROJECT-NAME>/openlane/`

![Result](images/done.png "Flow runs through")

Results are located in `../openlane/<CELL-NAME>/runs/results`.

![Result](images/PnR.png "Result of PnR")

### Interactive mode

This step is not necessary, but useful for troubleshooting! Further documentation can be found in [Openlane Interactive Mode Documentation](https://openlane-docs.readthedocs.io/en/rtd-develop/doc/advanced_readme.html).

Open a console in `/foss/designs/<PROJECT-NAME>/openlane/` and run the following command; the output folder will be prepared with the current config in `../openlane/<CELL-NAME>/runs/foobar`.

```shell
flow.tcl -interactive -design customcells -tag foobar -overwrite
```

When in interactive mode, step through the flow with the following commands:

```tcl
package require openlane
run_synthesis
run_floorplan
run_placement
run_cts
run_routing
write_powered_verilog -output_def $::env(TMP_DIR)/routing/$::env(DESIGN_NAME).powered.def -output_verilog $::env(TMP_DIR)/routing/$::env(DESIGN_NAME).powered.v 
run_magic
run_magic_spice_export
run_magic_drc
run_lvs
run_antenna_check
```

### Note

The following commands are often suggested in old VLSI workshop reports, but in our design environment, they will generate a second and identical custom-cell entry in the `merged.unpadded.lef` file at the step "detailed routing." The flow will then crash with the error `No valid access pattern`. Just include the LEF files in `config.tcl`:

```tcl
set lefs [glob $::env(DESIGN_DIR)/src/*.lef]
add_lefs -src $lefs
```
