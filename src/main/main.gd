extends Control

# ======================
# CONFIG
# ======================
@export var late_zero_scale := 2.0       # forgiveness multiplier
@export var fail_release_threshold := 1.0 # seconds before window end that counts as fail

var _input_pressed_internal: bool = false
var input_pressed: bool:
	set(value):
		if _input_pressed_internal == value:
			return
		_input_pressed_internal = value

		# update visuals
		_update_input_ui()
	get:
		return _input_pressed_internal


func _update_input_ui() -> void:
	if _input_pressed_internal:
		$bool_buttonbeingpressed.modulate = Color(0.0, 1.0, 0.0, 1.0)
		$bool_buttonbeingpressed.text = "YES"
	else:
		$bool_buttonbeingpressed.modulate = Color(1.0, 0.0, 0.0, 1.0)
		$bool_buttonbeingpressed.text = "NO"

# ======================
# STATE
# ======================
var breathing_phase := "exhale"          # always start on exhale

var accuracy_window_active := false
var window_start_ms := 0
var window_duration := 0.0

var accuracy := 0.0
var total_score := 0.0
var hits_count := 0
var cumulative_accuracy := 0.0
var fails := 0

var skip_next_accuracy := false
var skip_accuracy_threshold := 0.7  # near-next behavior

# ======================
# READY
# ======================
func _ready() -> void:
	# start breathing interval
	$Timers/breath_interval.start()

	# ensure input UI matches current internal state on startup
	_update_input_ui()

# ======================
# PROCESS HUD
# ======================
func _process(_delta: float) -> void:
	input_pressed = Input.is_action_pressed("input")
	
	$infolbls/breath_interval.text = "breath interval: " + str($Timers/breath_interval.wait_time)
	$infolbls/breath_interval_left.text = "breath interval time left: %.2f" % $Timers/breath_interval.time_left
	$infolbls/breath_accuracy_gap.text = "breath accuracy gap: " + str($Timers/breath_accuracy_cap.wait_time)
	$infolbls/breath_accuracy_gap_left.text = "breath accuracy gap time left: %.2f" % $Timers/breath_accuracy_cap.time_left
	$infolbls/breathing_phase.text = "phase: " + breathing_phase
	$infolbls/accuracy.text = "ACCURACY: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy)
	$infolbls/fails.text = "FAILS: " + str(fails)

# ======================
# INPUT
# ======================
func _input(_event: InputEvent) -> void:
	# EXHALE: press to hold
	if Input.is_action_just_pressed("input") and breathing_phase == "exhale":
		_try_score()
	# INHALE: release to complete
	elif Input.is_action_just_released("input") and breathing_phase == "inhale":
		_try_score()

# ======================
# CORE LOGIC
# ======================
func _try_score() -> void:
	var acc := _calculate_accuracy()
	if acc <= 0.0:
		_fail_phase()
		return
	_accept_action(acc)
	_finish_phase()

func _finish_phase() -> void:
	accuracy_window_active = false
	$Timers/breath_accuracy_cap.stop()
	
	# flip phase
	breathing_phase = "exhale" if breathing_phase == "inhale" else "inhale"
	$Timers/breath_interval.start()

func _fail_phase(flip_phase: bool = true) -> void:
	print("FAIL - " + breathing_phase)
	fails += 1
	accuracy_window_active = false
	$Timers/breath_accuracy_cap.stop()
	
	if flip_phase:
		# flip only if it's a normal fail (not window timeout fail)
		breathing_phase = "exhale" if breathing_phase == "inhale" else "inhale"
	
	$Timers/breath_interval.start()


# ======================
# TIMERS
# ======================
func _on_breath_interval_timeout() -> void:
	if skip_next_accuracy:
		skip_next_accuracy = false
		accuracy_window_active = false
		breathing_phase = "exhale" if breathing_phase == "inhale" else "inhale"
		$Timers/breath_interval.start()
		return
	_start_accuracy_window()

func _on_breath_accuracy_cap_timeout() -> void:
	if accuracy_window_active:
		# fail but **don’t flip**, let player try again in same phase
		_fail_phase(false)


func _start_accuracy_window() -> void:
	accuracy_window_active = true
	window_start_ms = Time.get_ticks_msec()
	window_duration = $Timers/breath_accuracy_cap.wait_time
	$Timers/breath_accuracy_cap.start()

# ======================
# SCORING
# ======================
func _calculate_accuracy() -> float:

	if window_duration <= 0.0:
		return 0.0

	var now_ms : int = Time.get_ticks_msec()
	var duration_ms : int = int(window_duration * 1000)
	@warning_ignore("integer_division")
	var center_ms : int = window_start_ms + duration_ms / 2
	@warning_ignore("integer_division")
	var ideal_ms : int = duration_ms / 2
	var dist : float = float(abs(now_ms - center_ms))

	# If player pressed too early (before the switch window), count as fail
	if dist > float(ideal_ms) * late_zero_scale:
		return 0.0

	var norm : float = 1.0 - (dist / (float(ideal_ms) * late_zero_scale))
	return clamp(round(norm * 100.0 * 100.0) / 100.0, 0.0, 100.0)

func _accept_action(acc: float) -> void:
	accuracy = acc
	total_score += acc
	hits_count += 1
	cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
	print("✔", breathing_phase, "accuracy:", accuracy, "AVG:", cumulative_accuracy)
