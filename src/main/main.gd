extends Control


var accuracy : float = 100.0
var first_breath : bool = true
var breathing_phase : String = "inhale"  # "inhale" or "exhale"
var total_score : float = 0.0
var hits_count : int = 0
var cumulative_accuracy : float = 100.0

var input_pressed : bool = false:
	set(value):
		input_pressed = value
		
		if value:
			$bool_buttonbeingpressed.modulate = Color(0.0, 1.0, 0.0, 1.0)
			$bool_buttonbeingpressed.text = "YES"
		else:
			$bool_buttonbeingpressed.modulate = Color(1.0, 0.0, 0.0, 1.0)
			$bool_buttonbeingpressed.text = "NO"

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


func _calculate_accuracy() -> float:
	# Calculate accuracy as a percentage (0..100) based on how close
	# the player's input was to the center of the accuracy window.
	# If it's the very first breath, return perfect score.
	var t = $Timers/breath_accuracy_cap
	if first_breath:
		return 100.0
	if t.wait_time <= 0.0:
		return 0.0
	var ideal = t.wait_time / 2.0
	var tl = t.time_left
	var dist = abs(tl - ideal)
	var normalized = 0.0
	if ideal > 0.0:
		normalized = clamp(1.0 - (dist / ideal), 0.0, 1.0)
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
		# wasn't started. Clear `first_breath` only when inhale succeeds.
		if $Timers/breath_accuracy_cap.time_left > 0.0 or first_breath:
			# Compute accuracy before stopping the timer so time_left is valid
			accuracy = _calculate_accuracy()
			# update cumulative
			total_score += accuracy
			hits_count += 1
			cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
			print("hoorah - inhale success - accuracy: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy))
			$Timers/breath_accuracy_cap.stop()
			breathing_phase = "exhale"
			first_breath = false
			$Timers/breath_interval.start()
		else:
			print("goober - inhale failed")
	
	# Validate exhale (button press - player starts holding again)
	elif Input.is_action_just_pressed("input") and breathing_phase == "exhale":
		if $Timers/breath_accuracy_cap.time_left > 0.0:
			# Compute accuracy based on when the player pressed during the
			# accuracy window.
			accuracy = _calculate_accuracy()
			# update cumulative
			total_score += accuracy
			hits_count += 1
			cumulative_accuracy = round((total_score / hits_count) * 100.0) / 100.0
			print("hoorah - exhale success - accuracy: " + str(accuracy) + "  AVG: " + str(cumulative_accuracy))
			$Timers/breath_accuracy_cap.stop()
			breathing_phase = "inhale"
			$Timers/breath_interval.start()
		else:
			print("goober - exhale failed")



func _on_breath_interval_timeout() -> void:
	if breathing_phase == "inhale":
		$Timers/breath_accuracy_cap.start()
	elif breathing_phase == "exhale":
		$Timers/breath_accuracy_cap.start()
