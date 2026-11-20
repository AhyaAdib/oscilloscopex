
Development Conventions & Workflow
Code-First Rule
All scenes (.tscn), scripts (.gd), shaders (.gdshader), and configurations are generated programmatically via CLI. Do not use the Godot GUI editor to construct scenes or connect signals.

Development Loop
Write code (scripts/, scenes/, tests/).

Run headless automated test suite via CLI.

Launch WSLg GUI and verify interactive behavior.

Update documentation (ROADMAP.md, CHANGELOG.md) and commit to Git.

Running Automated Tests
Bash
"$GODOT_BIN" --headless --path "$OSCILLO_ROOT" --script res://tests/run_tests.gd
