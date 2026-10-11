extends Control

@onready var money_label : Label = $MoneyLabel
@onready var job_pgbar : TextureProgressBar = $JobProgress
@onready var job_pglabel : Label = $JobProgressLabel

@export var show_job_progress: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	job_pgbar.visible = show_job_progress
	job_pglabel.visible = show_job_progress
	money_label.text = "Money: " + str(GameManager.money)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func job_progress(progress):
	job_pgbar.value = progress
