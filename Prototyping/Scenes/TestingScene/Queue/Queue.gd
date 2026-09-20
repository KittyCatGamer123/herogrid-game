extends Control

func init(gameref: GameTest, hero: GameTest.HEROS, steps: int):
	$ColorIcon.color = gameref.HeroRules[hero]["color"]
	$Title.text = gameref.HeroRules[hero]["name"]
	$Steps.text = str(steps, " Steps")
