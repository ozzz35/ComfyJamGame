class_name MusicTracks
extends RefCounted

const PACK := "res://assets/audio/music/melodic_autumn/Melodic Autumn - Blue Lava Music Pack/MP3 Files/"

const TRACKS: Dictionary = {
	"menu": PACK + "6 Cozy Fall Shop - Blue Lava.mp3",
	"hub": PACK + "hub.mp3",
	"yard_stroll": PACK + "StrollInTheField.ogg",
	"yard_sunset": PACK + "SunsetNap.ogg",
	"battle": PACK + "3 Bamboo Battle - Blue Lava.mp3",
	"finale": "res://assets/audio/music/october_rose.mp3",
}

const YARD_PLAYLIST: Array[String] = ["yard_stroll", "yard_sunset"]

const LOOP: Array[String] = ["menu", "hub", "battle", "finale"]
