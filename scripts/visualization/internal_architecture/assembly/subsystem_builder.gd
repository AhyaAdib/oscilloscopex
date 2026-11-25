class_name SubsystemBuilder
extends RefCounted

static func build_all_subsystems(assembly_root: Node3D) -> Dictionary:
	var nodes := {}
	var alu_mat := ComponentFactory.mat(Color(0.76, 0.75, 0.72), 0.38, 0.65)
	var bezel_mat := ComponentFactory.mat(Color(0.84, 0.78, 0.68), 0.45, 0.15)
	var metal_mat := ComponentFactory.mat(Color(0.78, 0.82, 0.86), 0.26, 0.88)
	var shield_mat := ComponentFactory.mat(Color(0.60, 0.66, 0.72), 0.32, 0.80)
	var copper_mat := ComponentFactory.mat(Color(0.86, 0.52, 0.24), 0.28, 0.85)
	var dark_mat := ComponentFactory.mat(Color(0.14, 0.15, 0.17), 0.45, 0.25)
	var knob_beige := ComponentFactory.mat(Color(0.76, 0.71, 0.61), 0.42, 0.1)
	var knob_red := ComponentFactory.mat(Color(0.72, 0.20, 0.18), 0.38, 0.15)

	# -------------------------------------------------------------------------
	# MECH-01: FRONT PANEL, CRT BEZEL, ROTARY KNOBS, SWITCHES & BNC JACKS (+Z)
	# -------------------------------------------------------------------------
	var front := _make_holder(assembly_root, "CHASSIS_FRONT")
	ComponentFactory.add_box(front, "FrontAluminumPanel", Vector3(0.376, 0.186, 0.005), Vector3.ZERO, alu_mat)
	# CRT Bezel Hood & Graticule Frame (left front x = -0.092, y = +0.019)
	ComponentFactory.add_box(front, "CRTBezelOuter", Vector3(0.132, 0.108, 0.018), Vector3(-0.092, 0.019, 0.009), bezel_mat)
	ComponentFactory.add_box(front, "CRTGraticuleWindow", Vector3(0.104, 0.084, 0.004), Vector3(-0.092, 0.019, 0.016), ComponentFactory.mat(Color(0.10, 0.36, 0.32), 0.15, 0.0, Color(0.12, 0.65, 0.50), 0.45, 0.45))
	# Lower CRT Control Knobs (Intensity, Focus, Scale Illum) + Power Pushbutton
	ComponentFactory.add_box(front, "PowerSwitchBtn", Vector3(0.014, 0.014, 0.012), Vector3(-0.162, -0.052, 0.006), knob_red)
	for ki in range(3):
		ComponentFactory.add_knob(front, "CRTKnob_" + str(ki), 0.009, 0.012, Vector3(-0.114 + float(ki) * 0.031, -0.042, 0.002), dark_mat, alu_mat)
	# Vertical CH1 & CH2 VOLTS/DIV Dual-Concentric Knobs, Position Knobs, Toggle Switches & BNCs
	for ch_x in [0.036, 0.098]:
		ComponentFactory.add_knob(front, "VoltsDivKnob", 0.015, 0.016, Vector3(ch_x, 0.028, 0.002), knob_beige, knob_red)
		ComponentFactory.add_knob(front, "VertPosKnob", 0.009, 0.012, Vector3(ch_x, -0.015, 0.002), knob_beige, dark_mat)
		ComponentFactory.add_box(front, "CouplingSlideSw", Vector3(0.008, 0.016, 0.008), Vector3(ch_x - 0.014, -0.056, 0.004), dark_mat)
		ComponentFactory.add_cyl(front, "FrontBNCJack", 0.007, 0.016, Vector3(ch_x + 0.008, -0.056, 0.008), Vector3(PI * 0.5, 0, 0), metal_mat, 14)
	# Horizontal TIME/DIV & Trigger Knobs
	ComponentFactory.add_knob(front, "TimeDivKnob", 0.016, 0.016, Vector3(0.148, 0.028, 0.002), knob_beige, knob_red)
	ComponentFactory.add_knob(front, "TrigLevelKnob", 0.010, 0.013, Vector3(0.148, -0.018, 0.002), knob_beige, dark_mat)
	ComponentFactory.add_cyl(front, "ExtTrigBNC", 0.0065, 0.014, Vector3(0.148, -0.056, 0.007), Vector3(PI * 0.5, 0, 0), metal_mat, 12)
	nodes["CHASSIS_FRONT"] = front

	# -------------------------------------------------------------------------
	# SUB-01: INPUT BNC & COUPLING RELAYS
	# -------------------------------------------------------------------------
	var s1 := _make_holder(assembly_root, "N1_INPUT")
	for bx in [-0.028, 0.028]:
		ComponentFactory.add_cyl(s1, "BNCRearBarrel", 0.0075, 0.024, Vector3(bx, -0.036, 0.006), Vector3(PI * 0.5, 0, 0), metal_mat, 14)
		ComponentFactory.add_box(s1, "CouplingCapHV", Vector3(0.016, 0.014, 0.014), Vector3(bx, -0.012, -0.004), ComponentFactory.mat(Color(0.92, 0.46, 0.16), 0.35, 0.1))
		ComponentFactory.add_box(s1, "ReedRelay", Vector3(0.014, 0.010, 0.010), Vector3(bx, 0.012, -0.004), dark_mat)
	ComponentFactory.add_dense_pcb(s1, "InputCouplingPCB", Vector3(0.076, 0.086, 0.004), Vector3(0, 0, -0.014), ArchitectureRegistry.SUBSYSTEMS[1]["accent"])
	nodes["N1_INPUT"] = s1

	# -------------------------------------------------------------------------
	# SUB-02: MULTI-WAFER ROTARY SWITCH SHAFT & SHIELDED STEP ATTENUATOR
	# -------------------------------------------------------------------------
	var s2 := _make_holder(assembly_root, "N2_COUPLING")
	ComponentFactory.add_box(s2, "AttenTinplateCan", Vector3(0.068, 0.092, 0.036), Vector3.ZERO, shield_mat)
	# Multi-wafer rotary switch shaft extending forward toward VOLTS/DIV knob (like Type 546 exploded diagram)
	ComponentFactory.add_cyl(s2, "RotarySwitchShaft", 0.0032, 0.092, Vector3(0, 0.024, 0.028), Vector3(PI * 0.5, 0, 0), metal_mat, 12)
	for wi in range(4):
		var wz := -0.008 + float(wi) * 0.018
		ComponentFactory.add_cyl(s2, "CeramicSwitchWafer_" + str(wi), 0.015, 0.003, Vector3(0, 0.024, wz), Vector3(PI * 0.5, 0, 0), bezel_mat, 14)
	ComponentFactory.add_dense_pcb(s2, "AttenCompensatedPCB", Vector3(0.062, 0.084, 0.004), Vector3(0, 0, 0.020), ArchitectureRegistry.SUBSYSTEMS[2]["accent"])
	nodes["N2_COUPLING"] = s2

	# -------------------------------------------------------------------------
	# SUB-03: VERTICAL CASCODE PREAMPLIFIER PCB
	# -------------------------------------------------------------------------
	var s3 := _make_holder(assembly_root, "N3_ATTENUATOR")
	ComponentFactory.add_dense_pcb(s3, "VertCascodePCB", Vector3(0.076, 0.102, 0.005), Vector3.ZERO, ArchitectureRegistry.SUBSYSTEMS[3]["accent"])
	ComponentFactory.add_cyl(s3, "MatchedJFETCan", 0.007, 0.012, Vector3(0, 0.022, 0.008), Vector3(PI * 0.5, 0, 0), metal_mat, 14)
	# Interconnect wiring bundle from Attenuator to Vertical Preamp
	ComponentFactory.add_wire(s3, "WireBundle_AttenToPreamp", Vector3(0, 0.028, 0.055), Vector3(0, 0.028, 0.004), 0.0018, ComponentFactory.mat(Color(0.20, 0.92, 0.72), 0.3, 0.1, Color(0.16, 0.85, 0.65), 0.8))
	nodes["N3_ATTENUATOR"] = s3

	# -------------------------------------------------------------------------
	# SUB-04: HELICAL COAXIAL DELAY LINE COIL (50 µs)
	# -------------------------------------------------------------------------
	var s4 := _make_holder(assembly_root, "N4_PREAMP")
	ComponentFactory.add_box(s4, "DelayChassisTray", Vector3(0.155, 0.005, 0.078), Vector3(0, -0.014, 0), dark_mat)
	for ci in range(9):
		var z_off := -0.028 + float(ci) * 0.007
		ComponentFactory.add_cyl(s4, "HelicalCoaxTurn_" + str(ci), 0.014, 0.142, Vector3(0, 0.004, z_off), Vector3(0, 0, PI * 0.5), copper_mat, 14)
	ComponentFactory.add_wire(s4, "CoaxFeedIn", Vector3(0.068, 0.045, 0.022), Vector3(0.055, 0.012, 0.022), 0.002, copper_mat)
	nodes["N4_PREAMP"] = s4

	# -------------------------------------------------------------------------
	# SUB-05: Y & X HIGH-VOLTAGE DEFLECTION AMPLIFIER BOARDS
	# -------------------------------------------------------------------------
	var s5 := _make_holder(assembly_root, "N5_DELAY_LINE")
	ComponentFactory.add_dense_pcb(s5, "VertDeflectDriverPCB", Vector3(0.064, 0.088, 0.005), Vector3(0.032, 0.012, 0.0), ArchitectureRegistry.SUBSYSTEMS[5]["accent"])
	ComponentFactory.add_dense_pcb(s5, "HorizDeflectDriverPCB", Vector3(0.064, 0.078, 0.005), Vector3(-0.024, -0.014, -0.020), Color(1.0, 0.68, 0.20))
	# Finned Aluminum Output Transistor Heatsink
	for fi in range(5):
		ComponentFactory.add_box(s5, "HeatsinkFin_" + str(fi), Vector3(0.003, 0.068, 0.024), Vector3(0.064 + float(fi) * 0.0045, 0.012, 0.0), dark_mat)
	# Deflection plate twisted-pair leads toward CRT neck
	ComponentFactory.add_wire(s5, "YPlateLeadTop", Vector3(0.015, 0.028, 0.0), Vector3(-0.068, 0.014, 0.0), 0.0016, ComponentFactory.mat(Color(0.24, 0.96, 0.78), 0.3, 0.2))
	ComponentFactory.add_wire(s5, "YPlateLeadBot", Vector3(0.015, -0.004, 0.0), Vector3(-0.068, -0.004, 0.0), 0.0016, ComponentFactory.mat(Color(0.24, 0.96, 0.78), 0.3, 0.2))
	nodes["N5_DELAY_LINE"] = s5

	# -------------------------------------------------------------------------
	# SUB-06: TRIGGER SCHMITT & MILLER SWEEP TIMEBASE PCB
	# -------------------------------------------------------------------------
	var s6 := _make_holder(assembly_root, "N6_VERT_DEFLECT")
	ComponentFactory.add_dense_pcb(s6, "TriggerMillerSweepPCB", Vector3(0.052, 0.112, 0.076), Vector3.ZERO, ArchitectureRegistry.SUBSYSTEMS[6]["accent"])
	ComponentFactory.add_cyl(s6, "TimeDivWaferShaft", 0.003, 0.088, Vector3(0.003, 0.032, 0.052), Vector3(PI * 0.5, 0, 0), metal_mat, 12)
	ComponentFactory.add_cyl(s6, "MillerPrecisionCap", 0.010, 0.026, Vector3(-0.006, 0.024, 0.016), Vector3(PI * 0.5, 0, 0), ComponentFactory.mat(Color(0.20, 0.55, 0.94), 0.3, 0.2), 12)
	nodes["N6_VERT_DEFLECT"] = s6

	# -------------------------------------------------------------------------
	# SUB-07: CRT CUTAWAY ASSEMBLY, CERAMIC NECK SOCKET & LIVE ELECTRON BEAM
	# -------------------------------------------------------------------------
	var s7 := _make_holder(assembly_root, "N7_TRIGGER")
	var glass_mat := ComponentFactory.mat(Color(0.35, 0.85, 1.0), 0.12, 0.1, Color(0.16, 0.65, 0.88), 0.45, 0.24)
	var beam_mat := ComponentFactory.mat(Color(0.22, 1.0, 0.72), 0.1, 0.0, Color(0.20, 1.0, 0.68), 3.4, 0.95)
	var plate_mat := ComponentFactory.mat(Color(0.92, 0.74, 0.28), 0.25, 0.85)

	ComponentFactory.add_cyl(s7, "CRTNeckGlass", 0.022, 0.155, Vector3(0, 0, -0.075), Vector3(PI * 0.5, 0, 0), glass_mat, 18)
	ComponentFactory.add_box(s7, "CRTFunnelGlass", Vector3(0.106, 0.086, 0.145), Vector3(0, 0, 0.072), glass_mat)
	ComponentFactory.add_box(s7, "PhosphorScreen", Vector3(0.102, 0.082, 0.004), Vector3(0, 0, 0.146), ComponentFactory.mat(Color(0.10, 0.42, 0.34), 0.2, 0.0, Color(0.14, 0.75, 0.55), 0.65, 0.55))

	# Ceramic Rear CRT Socket + Pin Harness (featured prominently in Type 546 exploded diagram)
	ComponentFactory.add_cyl(s7, "CeramicCRTSocket", 0.024, 0.018, Vector3(0, 0, -0.158), Vector3(PI * 0.5, 0, 0), bezel_mat, 16)
	for pi in range(6):
		var ang := float(pi) * TAU / 6.0
		ComponentFactory.add_cyl(s7, "CRTPin_" + str(pi), 0.0014, 0.016, Vector3(cos(ang) * 0.013, sin(ang) * 0.013, -0.170), Vector3(PI * 0.5, 0, 0), metal_mat, 8)

	# Electron Gun Stages + Deflection Plates + Beam
	ComponentFactory.add_cyl(s7, "HeaterCathode", 0.006, 0.024, Vector3(0, 0, -0.132), Vector3(PI * 0.5, 0, 0), ComponentFactory.mat(Color(1.0, 0.45, 0.12), 0.2, 0.0, Color(1.0, 0.42, 0.10), 2.8), 12)
	ComponentFactory.add_cyl(s7, "ControlGrid", 0.011, 0.014, Vector3(0, 0, -0.108), Vector3(PI * 0.5, 0, 0), metal_mat, 12)
	ComponentFactory.add_cyl(s7, "FocusAnode", 0.012, 0.022, Vector3(0, 0, -0.082), Vector3(PI * 0.5, 0, 0), shield_mat, 12)
	ComponentFactory.add_box(s7, "YPlateTop", Vector3(0.018, 0.002, 0.024), Vector3(0, 0.008, -0.044), plate_mat)
	ComponentFactory.add_box(s7, "YPlateBot", Vector3(0.018, 0.002, 0.024), Vector3(0, -0.008, -0.044), plate_mat)
	ComponentFactory.add_box(s7, "XPlateLeft", Vector3(0.002, 0.018, 0.024), Vector3(-0.009, 0, -0.014), plate_mat)
	ComponentFactory.add_box(s7, "XPlateRight", Vector3(0.002, 0.018, 0.024), Vector3(0.009, 0, -0.014), plate_mat)

	var beam := ComponentFactory.add_cyl(s7, "ElectronBeamCore", 0.0022, 0.275, Vector3(0, 0.004, 0.008), Vector3(PI * 0.5 - 0.03, 0, 0), beam_mat, 10)
	beam.name = "ElectronBeamCore"
	nodes["N7_TRIGGER"] = s7

	# -------------------------------------------------------------------------
	# SUB-08: LINEAR MAINS POWER SUPPLY, CAPACITOR BANK & HV CAGE
	# -------------------------------------------------------------------------
	var s8 := _make_holder(assembly_root, "N8_SWEEP")
	ComponentFactory.add_box(s8, "PSUBaseChassis", Vector3(0.185, 0.006, 0.082), Vector3(0, -0.048, 0), shield_mat)
	ComponentFactory.add_box(s8, "MainsTransformerWinding", Vector3(0.068, 0.066, 0.062), Vector3(0.048, -0.012, 0), copper_mat)
	ComponentFactory.add_box(s8, "MainsTransformerCore", Vector3(0.076, 0.046, 0.042), Vector3(0.048, -0.012, 0), dark_mat)
	var cap_mat := ComponentFactory.mat(Color(0.14, 0.36, 0.72), 0.3, 0.4)
	for cx in [-0.018, 0.006]:
		ComponentFactory.add_cyl(s8, "FilterCap_" + str(cx), 0.011, 0.046, Vector3(cx, -0.022, -0.012), Vector3.ZERO, cap_mat, 12)
	ComponentFactory.add_box(s8, "HVCRTMultiplierCage", Vector3(0.052, 0.048, 0.052), Vector3(-0.062, -0.020, 0), ComponentFactory.mat(Color(0.72, 0.18, 0.18), 0.35, 0.25))
	ComponentFactory.add_wire(s8, "HVAnodeLead", Vector3(-0.062, 0.006, 0), Vector3(-0.140, 0.062, 0.060), 0.0022, ComponentFactory.mat(Color(0.92, 0.18, 0.16), 0.35, 0.1))
	nodes["N8_SWEEP"] = s8

	# -------------------------------------------------------------------------
	# MECH-02: REAR PANEL, 5-BLADE COOLING FAN & PERFORATED EXHAUST GRILLE (-Z)
	# -------------------------------------------------------------------------
	var rear := _make_holder(assembly_root, "CHASSIS_REAR")
	ComponentFactory.add_box(rear, "RearPanelFrame", Vector3(0.376, 0.186, 0.005), Vector3.ZERO, alu_mat)
	# Circular Fan Shroud + Motor Hub + 5 Angled Cooling Fan Blades (matching Type 546 rear assembly)
	var fan_center := Vector3(0.072, 0.005, -0.004)
	ComponentFactory.add_cyl(rear, "FanShroudRing", 0.056, 0.014, fan_center, Vector3(PI * 0.5, 0, 0), dark_mat, 20)
	ComponentFactory.add_cyl(rear, "FanMotorHub", 0.016, 0.022, fan_center, Vector3(PI * 0.5, 0, 0), metal_mat, 14)
	for bi in range(5):
		var a := float(bi) * TAU / 5.0
		var blade := ComponentFactory.add_box(rear, "FanBlade_" + str(bi), Vector3(0.016, 0.036, 0.002), fan_center + Vector3(cos(a) * 0.032, sin(a) * 0.032, -0.004), alu_mat)
		blade.rotation = Vector3(0.38, 0.0, a + PI * 0.5)
	# Perforated Wire Exhaust Mesh Frame behind the fan
	ComponentFactory.add_box(rear, "ExhaustWireGrille", Vector3(0.128, 0.128, 0.003), fan_center + Vector3(0, 0, -0.018), shield_mat)
	# Rear IEC AC Mains Power Inlet & Fuse Holder
	ComponentFactory.add_box(rear, "IECMainsSocket", Vector3(0.044, 0.028, 0.018), Vector3(-0.115, -0.045, -0.008), dark_mat)
	ComponentFactory.add_cyl(rear, "MainsFuseCap", 0.007, 0.018, Vector3(-0.072, -0.045, -0.008), Vector3(PI * 0.5, 0, 0), dark_mat, 12)
	nodes["CHASSIS_REAR"] = rear

	# -------------------------------------------------------------------------
	# MECH-03: TOP & SIDE VENTED ENCLOSURE COVERS + CARRY HANDLE (+Y)
	# -------------------------------------------------------------------------
	var covers := _make_holder(assembly_root, "CHASSIS_COVERS")
	var cover_mat := ComponentFactory.mat(Color(0.56, 0.58, 0.60), 0.45, 0.45, Color(0, 0, 0), 0.0, 0.35)
	ComponentFactory.add_box(covers, "TopVentedCover", Vector3(0.376, 0.004, 0.356), Vector3(0, 0.094, 0), cover_mat)
	ComponentFactory.add_box(covers, "LeftVentedSide", Vector3(0.004, 0.184, 0.356), Vector3(-0.188, 0.0, 0), cover_mat)
	ComponentFactory.add_box(covers, "RightVentedSide", Vector3(0.004, 0.184, 0.356), Vector3(0.188, 0.0, 0), cover_mat)
	ComponentFactory.add_box(covers, "BottomBasePlate", Vector3(0.376, 0.004, 0.356), Vector3(0, -0.094, 0), alu_mat)
	ComponentFactory.add_box(covers, "TopCarryHandle", Vector3(0.22, 0.012, 0.024), Vector3(0, 0.116, 0.02), dark_mat)
	nodes["CHASSIS_COVERS"] = covers

	return nodes

static func _make_holder(parent: Node3D, sub_id: String) -> Node3D:
	var cfg := ArchitectureRegistry.get_by_id(sub_id)
	var holder := Node3D.new()
	holder.name = sub_id
	holder.position = cfg["assembled_pos"]
	parent.add_child(holder)
	return holder
