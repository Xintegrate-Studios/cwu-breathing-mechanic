extends Control

# ======================
# CONFIG
# ======================
var late_zero_scale : float = 2.0           # forgiveness multiplier
var skip_accuracy_threshold : float = 0.7   # seconds to detect near-next

# ======================
# STATE
# ======================
var accuracy : float = 100.0
var first_breath : bool = true
var breathing_phase : String = "exhale"  # "inhale" or "exhale"
var total_score : float = 0.0
var hits_count : int = 0
var cumulative_accuracy : float = 100.0

var input_pressed : bool = false

# accuracy window
var accuracy_window_active : bool = false
var accuracy_window_start_ms : int = 0
var accuracy_window_duration : float = 0.0
var skip_next_accuracy : bool = false

# ======================
# READY
# ======================
func _ready() -> void:
	$Timers/breath_interval.start()  # start breathing automatically

# ======================
# PROCESS (HUD)
# ======================
func _process(_delta: float) -> void:
	input_pressed = Input.is_action_pressed("input")

	$infolbls/breath_interval.text = "breath interval: " + str($Timers/breath_interval.wait_time)
	$infolbls/breath_accuracy_gap.text = "breath accuracy gap: " + str($Timers/breath_accuracy_cap.wait_time)
	$infolbls/breath_accuracy_gap_left.text = "breath accuracy gap time left: %.2f" % $Timers/breath_accuracy_cap.time_left
	$infolbls/breath_interval_left.text = "breath interval time left: %.2f" % $Timers/breath_interval.time_left
	$infolbls/first_breath.text = "first breath? " + str(first_breath)
	$infolbls/breathing_phase.text = "phase: " + breathing_phase
	$infolbls/accuracy.text = "ACCURACY: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy)

	# Optional: change HUD color based on accuracy
	if accuracy <= 60.0 and accuracy > 30:
		$infolbls/accuracy.modulate = Color(1.0, 1.0, 0.49, 1.0)
	elif accuracy <= 30.0:
		$infolbls/accuracy.modulate = Color(1.0, 0.0, 0.0, 1.0)
	else:
		$infolbls/accuracy.modulate = Color(1.0, 1.0, 1.0, 1.0)

# ======================
# INPUT HANDLER
# ======================
func _input(_event: InputEvent) -> void:
	if _event.is_action_pressed("input"):
		input_pressed = true
	elif _event.is_action_released("input"):
		input_pressed = false

	# Determine action type
	var is_inhale_action = (breathing_phase == "inhale" and not input_pressed)   # release = inhale
	var is_exhale_action = (breathing_phase == "exhale" and input_pressed)       # press = exhale

	if is_inhale_action or is_exhale_action:
		_try_score_nearnext()

# ======================
# SCORING / LOGIC
# ======================
func _try_score_nearnext() -> void:
	var interval_t = $Timers/breath_interval
	var now_ms = Time.get_ticks_msec()

	# Near-next detection: acting near end of interval
	if interval_t.time_left > 0.0 and interval_t.time_left <= skip_accuracy_threshold:
		var future_start_ms = now_ms + int(interval_t.time_left * 1000)
		var acc = _compute_accuracy_for_window(future_start_ms, $Timers/breath_accuracy_cap.wait_time)
		skip_next_accuracy = true
		_accept_action(acc)
		accuracy_window_active = false
		$Timers/breath_accuracy_cap.stop()
		# Flip phase and restart interval
		breathing_phase = "exhale" if breathing_phase == "inhale" else "inhale"
		$Timers/breath_interval.start()
		return

	# Normal scoring
	var acc = _calculate_accuracy()
	if acc > 0.0 or first_breath:
		_accept_action(acc)
		accuracy_window_active = false
		$Timers/breath_accuracy_cap.stop()
		# Flip phase for next window
		breathing_phase = "exhale" if breathing_phase == "inhale" else "inhale"
		first_breath = false
		$Timers/breath_interval.start()
	else:
		print("missed input")

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

	# Start accuracy window for current phase
	accuracy_window_active = true
	accuracy_window_start_ms = Time.get_ticks_msec()
	accuracy_window_duration = $Timers/breath_accuracy_cap.wait_time
	$Timers/breath_accuracy_cap.start()

func _on_breath_accuracy_cap_timeout() -> void:
	accuracy_window_active = false
	print("accuracy window expired")

# ======================
# ACCURACY CALC
# ======================
func _calculate_accuracy() -> float:
	if first_breath:
		return 100.0
	if accuracy_window_duration <= 0.0:
		return 0.0

	var now_ms = Time.get_ticks_msec()
	var center_ms = accuracy_window_start_ms + int(accuracy_window_duration * 500.0)
	var ideal_ms = int(accuracy_window_duration * 500.0)
	var dist_ms = abs(now_ms - center_ms)
	if dist_ms > int(float(ideal_ms) * late_zero_scale):
		return 0.0
	var normalized = clamp(1.0 - (float(dist_ms) / (float(ideal_ms) * late_zero_scale)), 0.0, 1.0)
	return round(normalized * 100.0 * 100.0) / 100.0

func _compute_accuracy_for_window(start_ms: int, duration: float) -> float:
	if first_breath:
		return 100.0
	if duration <= 0.0:
		return 0.0
	var now_ms = Time.get_ticks_msec()
	var center_ms = start_ms + int(duration * 500.0)
	var ideal_ms = int(duration * 500.0)
	var dist_ms = abs(now_ms - center_ms)
	if dist_ms > int(float(ideal_ms) * late_zero_scale):
		return 0.0
	var normalized = clamp(1.0 - (float(dist_ms) / (float(ideal_ms) * late_zero_scale)), 0.0, 1.0)
	return round(normalized * 100.0 * 100.0) / 100.0

# ======================
# ACCEPT ACTION
# ======================
func _accept_action(acc: float) -> void:
	accuracy = acc
	total_score += acc
	hits_count += 1
	cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
	print("✔", breathing_phase, "accuracy:", accuracy, "AVG:", cumulative_accuracy)

# ======================
# MANUAL INPUT VISUAL
# ======================
func set_input_pressed(value: bool) -> void:
	input_pressed = value
	if value:
		$bool_buttonbeingpressed.modulate = Color(0,1,0,1)
		$bool_buttonbeingpressed.text = "YES"
	else:
		$bool_buttonbeingpressed.modulate = Color(1,0,0,1)
		$bool_buttonbeingpressed.text = "NO"
