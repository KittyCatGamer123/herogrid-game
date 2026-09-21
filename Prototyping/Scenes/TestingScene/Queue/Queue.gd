extends Button

var game_ref: GameTest
var path = []

func init(gameref: GameTest, hero: GameTest.HEROS, steps: int):
	game_ref = gameref
	$ColorIcon.color = gameref.HeroRules[hero]["color"]
	$Title.text = gameref.HeroRules[hero]["name"]
	$Steps.text = str(steps, " Steps")

func mouse_enter() -> void:
	if not game_ref.run_mode_active:
		game_ref.drawn_path = path

func mouse_exit() -> void:
	if not game_ref.run_mode_active:
		game_ref.drawn_path = []
