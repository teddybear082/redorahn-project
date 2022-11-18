extends ColorRect

var flash_intensity = 1.0
var flash_timer = 0.0
var flash_duration = 1.0


func _process(delta):
	if flash_timer > 0.0:
		self.color.a = flash_intensity * flash_timer / flash_duration
		flash_timer -= delta
		if (flash_timer <= 0.0):
			flash_timer = 0.0
			self.visible = false


func flash(color, duration):
	self.visible = true
	self.color = color
	flash_intensity = color.a
	flash_timer = duration
	flash_duration = duration
