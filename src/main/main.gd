extends Control


var accuracy : float = 100.0
var first_breath : bool = true
var breathing_phase : String = "inhale"  # "inhale" or "exhale"
var total_score : float = 0.0
var hits_count : int = 0
var cumulative_accuracy : float = 100.0

var input_pressed: bool = false:
	set(value):
		input_pressed = value
		if value:
			$bool_buttonbeingpressed.modulate = Color(0.0, 1.0, 0.0, 1.0)
			$bool_buttonbeingpressed.text = "YES"
		else:
			$bool_buttonbeingpressed.modulate = Color(1.0, 0.0, 0.0, 1.0)
			$bool_buttonbeingpressed.text = "NO"

# Track the accuracy window so we can compute accuracy even when
# the player presses/releases before or after the Timer is running.
var accuracy_window_active: bool = false
var accuracy_window_start_ms: int = 0
var accuracy_window_duration: float = 0.0
var skip_next_accuracy: bool = false
var skip_accuracy_threshold: float = 0.7
# If the player is this factor * the ideal offset late, accuracy becomes 0.
var late_zero_scale: float = 2.0

func _process(_delta: float) -> void:
	input_pressed = Input.is_action_pressed("input")
	$infolbls/breath_interval.text = "breath interval: " + str($Timers/breath_interval.wait_time)
	$infolbls/breath_accuracy_gap.text = "breath accuracy gap: " + str($Timers/breath_accuracy_cap.wait_time)
	
	$infolbls/breath_accuracy_gap_left.text = "breath accuracy gap time left: " + "%.2f" % $Timers/breath_accuracy_cap.time_left
	$infolbls/breath_interval_left.text = "breath interval time left: " + "%.2f" % $Timers/breath_interval.time_left
	
	$infolbls/first_breath.text = "first breath? " + str(first_breath)
	$infolbls/breathing_phase.text = "phase: " + breathing_phase
	
	
	$infolbls/accuracy.text = "ACCURACY: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy)
	if accuracy <= 60.0 and accuracy > 30:
		$infolbls/accuracy.modulate = Color(1.0, 1.0, 0.49, 1.0)
	elif accuracy <= 30.0:
		$infolbls/accuracy.modulate = Color(1.0, 0.0, 0.0, 1.0)
	else:
		$infolbls/accuracy.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _ready() -> void:
	# Start the breathing cycle automatically on scene ready.
	$Timers/breath_interval.start()


func _calculate_accuracy() -> float:
	# Calculate accuracy as a percentage (0..100) based on how close
	# the player's input time was to the center of the accuracy window.
	# If it's the very first breath, return perfect score.
	if first_breath:
		return 100.0

	# Ensure we have a positive duration to measure against.
	var duration = accuracy_window_duration
	if duration <= 0.0:
		return 0.0

	var now_ms = Time.get_ticks_msec()
	var center_ms = accuracy_window_start_ms + int(duration * 500.0)
	var ideal_ms = int(duration * 500.0)
	var dist_ms = abs(now_ms - center_ms)
	if ideal_ms <= 0:
		return 0.0
	# If we're very late beyond the configured scale, it's instant zero.
	if dist_ms > int(float(ideal_ms) * late_zero_scale):
		return 0.0
	var normalized = clamp(1.0 - (float(dist_ms) / (float(ideal_ms) * late_zero_scale)), 0.0, 1.0)
	var percent = normalized * 100.0
	return round(percent * 100.0) / 100.0


func _compute_accuracy_for_window(start_ms: int, duration: float) -> float:
	if first_breath:
		return 100.0
	if duration <= 0.0:
		return 0.0
	var now_ms = Time.get_ticks_msec()
	var center_ms = start_ms + int(duration * 500.0)
	var ideal_ms = int(duration * 500.0)
	var dist_ms = abs(now_ms - center_ms)
	if ideal_ms <= 0:
		return 0.0
	if dist_ms > int(float(ideal_ms) * late_zero_scale):
		return 0.0
	var normalized = clamp(1.0 - (float(dist_ms) / (float(ideal_ms) * late_zero_scale)), 0.0, 1.0)
	var percent = normalized * 100.0
	return round(percent * 100.0) / 100.0


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("input") and first_breath:
		# Start the first inhale, but don't clear `first_breath` yet.
		# We want the release (end of inhale) to succeed even without
		# the accuracy timer having been started.
		breathing_phase = "inhale"
		# Start the breathing cycle immediately when the player begins
		# the first inhale so the timers behave consistently.
		$Timers/breath_interval.start()
	
	# Validate inhale (button release - player stops holding)
	elif Input.is_action_just_released("input") and breathing_phase == "inhale":
		# For the very first inhale, allow success even if accuracy timer
		# wasn't started. Also detect if the player acted near the end of
		# the current interval — in that case compute accuracy against the
		# upcoming accuracy window and skip it.
		var interval_t = $Timers/breath_interval
		if interval_t.time_left > 0.0 and interval_t.time_left <= skip_accuracy_threshold:
			var future_start_ms = Time.get_ticks_msec() + int(interval_t.time_left * 1000)
			accuracy = _compute_accuracy_for_window(future_start_ms, $Timers/breath_accuracy_cap.wait_time)
			skip_next_accuracy = true
			$Timers/breath_accuracy_cap.stop()
			accuracy_window_active = false
			# restart interval and accept as success
			if first_breath or accuracy > 0.0:
				total_score += accuracy
				hits_count += 1
				cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
				print("hoorah - inhale (near-next) success - accuracy: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy))
				breathing_phase = "exhale"
				first_breath = false
				$Timers/breath_interval.start()
			else:
				print("goober - inhale (near-next) failed - accuracy: " + str(accuracy))
			return
		# otherwise compute against current/active window
		accuracy = _calculate_accuracy()
		if first_breath or accuracy > 0.0:
			total_score += accuracy
			hits_count += 1
			cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
			print("hoorah - inhale success - accuracy: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy))
			$Timers/breath_accuracy_cap.stop()
			accuracy_window_active = false
			breathing_phase = "exhale"
			first_breath = false
			$Timers/breath_interval.start()
		else:
			print("goober - inhale failed - accuracy: " + str(accuracy))
	
	# Validate exhale (button press - player starts holding again)
	elif Input.is_action_just_pressed("input") and breathing_phase == "exhale":
		# Detect acting near the interval end (skip-next behavior)
		var interval_t = $Timers/breath_interval
		if interval_t.time_left > 0.0 and interval_t.time_left <= skip_accuracy_threshold:
			var future_start_ms = Time.get_ticks_msec() + int(interval_t.time_left * 1000)
			accuracy = _compute_accuracy_for_window(future_start_ms, $Timers/breath_accuracy_cap.wait_time)
			skip_next_accuracy = true
			$Timers/breath_accuracy_cap.stop()
			accuracy_window_active = false
			if first_breath or accuracy > 0.0:
				total_score += accuracy
				hits_count += 1
				cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
				print("hoorah - exhale (near-next) success - accuracy: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy))
				breathing_phase = "inhale"
				$Timers/breath_interval.start()
			else:
				print("goober - exhale (near-next) failed - accuracy: " + str(accuracy))
			return
		# otherwise compute against current/active window
		accuracy = _calculate_accuracy()
		if first_breath or accuracy > 0.0:
			total_score += accuracy
			hits_count += 1
			cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
			print("hoorah - exhale success - accuracy: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy))
			$Timers/breath_accuracy_cap.stop()
			accuracy_window_active = false
			breathing_phase = "inhale"
			$Timers/breath_interval.start()
		else:
			print("goober - exhale failed - accuracy: " + str(accuracy))



func _on_breath_interval_timeout() -> void:
	# If flagged to skip the next accuracy window, don't start it —
	# toggle phase and restart the interval to continue the cycle.
	if skip_next_accuracy:
		skip_next_accuracy = false
		accuracy_window_active = false
		if breathing_phase == "inhale":
			breathing_phase = "exhale"
		else:
			breathing_phase = "inhale"
		$Timers/breath_interval.start()
		return
	
	if breathing_phase == "inhale":
		$Timers/breath_accuracy_cap.start()
		accuracy_window_active = true
		accuracy_window_start_ms = Time.get_ticks_msec()
		accuracy_window_duration = $Timers/breath_accuracy_cap.wait_time
	elif breathing_phase == "exhale":
		$Timers/breath_accuracy_cap.start()
		accuracy_window_active = true
		accuracy_window_start_ms = Time.get_ticks_msec()
		accuracy_window_duration = $Timers/breath_accuracy_cap.wait_time


func _on_breath_accuracy_cap_timeout() -> void:
	# Called when the accuracy window finishes on its own.
	accuracy_window_active = false
