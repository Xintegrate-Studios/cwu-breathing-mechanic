extends Control


var accuracy : float = 100.0
var first_breath : bool = true

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
	
	
	$infolbls/accuracy.text = "ACCURACY: " + str(accuracy)
	if accuracy <= 60.0 and accuracy > 30:
		$infolbls/accuracy.modulate = Color(1.0, 1.0, 0.49, 1.0)
	elif accuracy <= 30.0:
		$infolbls/accuracy.modulate = Color(1.0, 0.0, 0.0, 1.0)
	else:
		$infolbls/accuracy.modulate = Color(1.0, 1.0, 1.0, 1.0)



func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("input") and first_breath:
		first_breath = false
		$Timers/breath_interval.start()
	
	
	if Input.is_action_just_released("input"):
		if $Timers/breath_accuracy_cap.time_left > 0.0:
			print("hoorah")
			$Timers/breath_accuracy_cap.stop()
			$Timers/breath_interval.start()
		else:
			print("goober")



func _on_breath_interval_timeout() -> void:
	$Timers/breath_accuracy_cap.start()
