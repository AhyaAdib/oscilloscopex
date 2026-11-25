class_name ArchitectureRegistry
extends RefCounted

const SUBSYSTEMS := [
	{
		"id": "CHASSIS_FRONT",
		"code": "MECH-01",
		"title": "FRONT PANEL, BEZEL & KNOB ASSEMBLY",
		"role": "Operator Control Interface",
		"assembled_pos": Vector3(0.0, 0.105, 0.181),
		"explode_offset": Vector3(0.0, 0.0, 0.24),
		"accent": Color(0.24, 0.88, 0.98),
		"equation": "Control Routing → Front Faceplate & CRT Bezel",
		"desc": "Brushed aluminum front panel with CRT graticule bezel, rotary control knobs, toggle switches, and BNC input jacks."
	},
	{
		"id": "N1_INPUT",
		"code": "SUB-01",
		"title": "1. INPUT BNC & COUPLING RELAYS",
		"role": "Vertical Input & AC/DC/GND Selector",
		"assembled_pos": Vector3(0.068, 0.086, 0.132),
		"explode_offset": Vector3(0.16, 0.03, 0.15),
		"accent": Color(0.18, 0.95, 0.68),
		"equation": "DC: v_out = v_in  |  GND: 0V  |  AC: H(s) = sRC/(1+sRC)",
		"desc": "Coaxial BNC rear barrels, overvoltage clamp diodes, high-voltage DC-blocking film capacitors, and mechanical coupling slide switches."
	},
	{
		"id": "N2_COUPLING",
		"code": "SUB-02",
		"title": "2. WAFER ROTARY SWITCH & ATTENUATOR",
		"role": "Compensated Step Divider (1x / 10x)",
		"assembled_pos": Vector3(0.068, 0.095, 0.072),
		"explode_offset": Vector3(0.24, 0.07, 0.08),
		"accent": Color(0.32, 0.80, 1.0),
		"equation": "v_att(t) = v_coup(t) · R2 / (R1 + R2)",
		"desc": "Multi-wafer ceramic rotary switch shaft driving a tinplate-shielded frequency-compensated RC step attenuator."
	},
	{
		"id": "N3_ATTENUATOR",
		"code": "SUB-03",
		"title": "3. VERTICAL CASCODE PREAMPLIFIER",
		"role": "Low-Noise JFET Differential Gain PCB",
		"assembled_pos": Vector3(0.068, 0.102, 0.005),
		"explode_offset": Vector3(0.26, 0.12, 0.01),
		"accent": Color(0.22, 0.96, 0.58),
		"equation": "v_amp(t) = clamp(Av · v_att(t), -40V, +40V)",
		"desc": "Double-sided vertical amplifier PCB populated with matched JFET pair, axial precision resistors, trimpots, and decoupling capacitors."
	},
	{
		"id": "N4_PREAMP",
		"code": "SUB-04",
		"title": "4. COAXIAL DELAY LINE COIL",
		"role": "50 µs Vertical Signal Propagation Delay",
		"assembled_pos": Vector3(-0.005, 0.034, -0.025),
		"explode_offset": Vector3(0.0, -0.10, -0.02),
		"accent": Color(0.98, 0.76, 0.22),
		"equation": "v_del(t) = v_amp(t - τ_d),   τ_d = 50 µs",
		"desc": "Multi-turn helical coaxial delay line mounted on lower chassis rails so the horizontal sweep triggers prior to vertical deflection."
	},
	{
		"id": "N5_DELAY_LINE",
		"code": "SUB-05",
		"title": "5. Y & X DEFLECTION DRIVER BOARDS",
		"role": "High-Voltage Push-Pull CRT Amplifiers",
		"assembled_pos": Vector3(-0.018, 0.118, -0.052),
		"explode_offset": Vector3(0.18, 0.16, -0.08),
		"accent": Color(0.28, 0.96, 0.84),
		"equation": "y(t) = K_y · (v_del(t) + V_pos)",
		"desc": "Finned heatsinked push-pull vertical (Y±) and horizontal (X±) output amplifier boards wired directly to the CRT deflection pins."
	},
	{
		"id": "N6_VERT_DEFLECT",
		"code": "SUB-06",
		"title": "6. TRIGGER SCHMITT & MILLER TIMEBASE",
		"role": "Synchronization & Sawtooth Sweep PCB",
		"assembled_pos": Vector3(0.145, 0.098, 0.042),
		"explode_offset": Vector3(0.30, 0.05, 0.03),
		"accent": Color(1.0, 0.66, 0.18),
		"equation": "x(t) = x_0 + S_x · (t - t_trig)   [-5V → +5V]",
		"desc": "Schmitt trigger comparator and Miller integrator timing capacitor bank mounted on a dedicated right-hand timebase card."
	},
	{
		"id": "N7_TRIGGER",
		"code": "SUB-07",
		"title": "7. CRT CUTAWAY, ELECTRON GUN & BEAM",
		"role": "Electrostatic Cathode-Ray Tube Assembly",
		"assembled_pos": Vector3(-0.092, 0.124, -0.005),
		"explode_offset": Vector3(-0.22, 0.09, 0.04),
		"accent": Color(0.22, 0.95, 1.0),
		"equation": "r_beam(t) = [x0 + K_x·V_x(t),  y0 + K_y·V_y(t)]",
		"desc": "Mu-metal shielded CRT envelope with ceramic base socket, glowing heater/cathode, focus grid, Y±/X± deflection plates, and phosphor screen."
	},
	{
		"id": "N8_SWEEP",
		"code": "SUB-08",
		"title": "8. LINEAR POWER SUPPLY & HV CAGE",
		"role": "Mains Transformer, Rectifier & -2kV CRT Supply",
		"assembled_pos": Vector3(0.068, 0.068, -0.125),
		"explode_offset": Vector3(0.14, 0.04, -0.14),
		"accent": Color(0.95, 0.36, 0.32),
		"equation": "V_DC = ±15V, +5V, +120V Defl, -2000V CRT Cathode",
		"desc": "Laminated EI mains power transformer, bridge rectifier, bulk electrolytic filter capacitors, and shielded high-voltage CRT multiplier."
	},
	{
		"id": "CHASSIS_REAR",
		"code": "MECH-02",
		"title": "REAR PANEL, COOLING FAN & EXHAUST GRILLE",
		"role": "Thermal Management & Mains Inlet",
		"assembled_pos": Vector3(0.0, 0.105, -0.182),
		"explode_offset": Vector3(0.0, 0.0, -0.26),
		"accent": Color(0.55, 0.78, 0.95),
		"equation": "Forced-Air Exhaust Cooling + AC Mains Fuse",
		"desc": "Rear chassis plate with 5-blade axial cooling fan, motor hub, perforated wire exhaust grille, IEC AC inlet, and fuse carrier."
	},
	{
		"id": "CHASSIS_COVERS",
		"code": "MECH-03",
		"title": "PERFORATED CABINET COVERS & RAILS",
		"role": "EMI Shielded Enclosure Panels",
		"assembled_pos": Vector3(0.0, 0.105, 0.0),
		"explode_offset": Vector3(0.0, 0.22, 0.0),
		"accent": Color(0.42, 0.68, 0.85),
		"equation": "Faraday EMI Chassis Enclosure",
		"desc": "Top and side vented steel enclosure panels with rubber feet and top carrying handle."
	}
]

static func get_by_id(id: String) -> Dictionary:
	for item in SUBSYSTEMS:
		if item["id"] == id:
			return item
	return SUBSYSTEMS[0]
