extends Control

@onready var money_label : Label = $MoneyLabel
@onready var job_pgbar : TextureProgressBar = $JobProgress
@onready var job_pglabel : Label = $JobProgressLabel
@onready var job_startprompt : Label = $JobStartPrompt
@onready var job_finishedprompt : Label = $JobFinishedPrompt

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

func update_ui():
	money_label.text = "Money: " + str(GameManager.money)

func jobstart_prompt(visibility : bool, pos : Vector2):
	job_startprompt.visible = visibility
	var half = job_startprompt.size / 2
	job_startprompt.position = pos - Vector2(job_startprompt.size.x * 0.5, job_startprompt.size.y)
	
