extends KinematicBody2D

export (PackedScene) var Bullet

export (int) var health = 10
export (int) var maxHealth = 10
export (int) var power = 50
export (int) var maxPower = 50
export (int) var powerRegen = 1
export (int) var powerRegenFactor = 1
export (int) var dashCharges = 4
export (int) var maxDashCharges = 4

export (int) var rapidFireConsumption = 2
export (int) var shotgunConsumption = 10

export (int) var speed = 200
export var movementFactor = 1
export (int) var dashDist = 2000
export var dashFactor = 1

var velocity = Vector2()
var dashVelocity = Vector2()

var shootTriggerTimer = null
export var bulletDelay = 1
var canShoot = true

var rapidFireTimer = null
export var rapidFireDelay = .09
var canRapidFire = true

var dashTimer = null
export var dashDelay = 4
var canDash = true

var powerRegenTimer = null
export var powerRegenDelay = 1
var canPowerRegen = false

var lookDir = 1
var mouseDir

func _ready():
	shootTriggerTimer = Timer.new()
	shootTriggerTimer.set_one_shot(true)
	shootTriggerTimer.set_wait_time(bulletDelay)
	shootTriggerTimer.connect("timeout", self, "onShootTimeout")
	add_child(shootTriggerTimer)
	
	rapidFireTimer = Timer.new()
	rapidFireTimer.set_one_shot(true)
	rapidFireTimer.set_wait_time(rapidFireDelay)
	rapidFireTimer.connect("timeout", self, "onRapidFireTimeout")
	add_child(rapidFireTimer)
	
	dashTimer = Timer.new()
	dashTimer.set_one_shot(true)
	dashTimer.set_wait_time(dashDelay)
	dashTimer.connect("timeout", self, "onDashTimeout")
	add_child(dashTimer)
	
	powerRegenTimer = Timer.new()
	powerRegenTimer.set_one_shot(true)
	powerRegenTimer.set_wait_time(powerRegenDelay)
	powerRegenTimer.connect("timeout", self, "onPowerRegenTimeout")
	add_child(powerRegenTimer)

# On shootTriggerTimer timeout
func onShootTimeout():
	canShoot = true

func onRapidFireTimeout():
	canRapidFire = true

func onDashTimeout():
	canDash = true

func onPowerRegenTimeout():
	canPowerRegen = true

func calculateDirection():
	mouseDir = rad2deg(get_angle_to(get_global_mouse_position()))
	
	if mouseDir > -90 && mouseDir <= 90:
		lookDir = 1
	elif mouseDir > 90 || mouseDir <= -90:
		lookDir = -1
	else:
		lookDir = 1
	
	# Rotate arm/gun toward mouse
	$ArmGun.rotation_degrees = mouseDir #rad2deg(get_angle_to(get_global_mouse_position()))
	
	if lookDir == 1:
		$Sprite.flip_h = false
		$ArmGun/Sprite.flip_v = false
	elif lookDir == -1:
		$Sprite.flip_h = true
		$ArmGun/Sprite.flip_v = true
	else:
		$Sprite.flip_h = false
		$ArmGun/Sprite.flip_v = false

func stats():
	# Clamp health between the min and max
	health = clamp(health, 0, maxHealth)
	
	if health <= 0:
		queue_free()
	
	# Clamp power between min and max
	power = clamp(power, 0, maxPower)
	
	# Make power regen faster when below 1/5 of its maximum
	if power < maxPower/5:
		powerRegenFactor = 2
	
	# Regen power when below maxPower if canPowerRegen
	# Otherwise start the timer so that canPowerRegen can be true to regen
	if power < maxPower:
		if canPowerRegen:
			power = power + powerRegen * powerRegenFactor
		else:
			powerRegenTimer.start()
	
	# Set can power regen back to false when full of power
	if power >= maxPower:
		canPowerRegen = false
	
	# Clamp dash charges between min and max
	dashCharges = clamp(dashCharges, 0, maxDashCharges)
	
	print(power)
	print(canPowerRegen)

func get_input():
	# Movement
	velocity = Vector2()
	dashVelocity = Vector2()
	
	if Input.is_action_pressed("game_up"):
		velocity.y -= 1
	if Input.is_action_pressed("game_down"):
		velocity.y += 1
	if Input.is_action_pressed("game_left"):
		velocity.x -= 1
	if Input.is_action_pressed("game_right"):
		velocity.x += 1
	
	if Input.is_action_just_released("game_dodge") && canDash && dashCharges > 0:
		canDash = false
		
		dashCharges -= 1
		
		dashVelocity = velocity.normalized() * dashDist * dashFactor
		
		dashTimer.start()
	
	velocity = velocity.normalized() * speed * movementFactor + dashVelocity
	
	# Weapons
	# Mode 1
	if Input.is_action_pressed("game_attack_1") && canShoot && power >= rapidFireConsumption:
		var b = Bullet.instance()
		
		if canRapidFire:
			canRapidFire = false
			
			# Consume power per shot
			power -= rapidFireConsumption
			
			owner.add_child(b)
			b.transform = $ArmGun/BulletOrigin0.global_transform
			
			rapidFireTimer.start()
		else:
			pass
	
	# Mode 2
	if Input.is_action_just_released("game_attack_2") && canShoot && power >= shotgunConsumption:
		var b = Bullet.instance()
		var bb = Bullet.instance()
		var bbb = Bullet.instance()
		
		canShoot = false
		
		# Consume power per shot
		power -= shotgunConsumption
		
		owner.add_child(b)
		b.transform = $ArmGun/BulletOrigin0.global_transform
		owner.add_child(bb)
		bb.transform = $ArmGun/BulletOrigin1.global_transform
		owner.add_child(bbb)
		bbb.transform = $ArmGun/BulletOrigin2.global_transform
		
		shootTriggerTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Calculates sprite flipping, etc.
	calculateDirection()
	
	# Movement and weapons
	get_input()
	velocity = move_and_slide(velocity) * delta
	
	# Stats calculations
	stats()
