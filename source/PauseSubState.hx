package;

import Controls.Control;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;

import openfl.display.BlendMode;
import flash.system.System;

/**
* Substate used to create a pause menu for `PlayState`.
*/
class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options Menu', 'Exit'];
	var difficultyChoices = [];
	var exitChoices = ['Exit To Song Menu', 'Exit To Main Menu', 'Exit Game'];
	var curSelected:Int = 0;
	public static var changedOptions:Bool = false;
	public static var transferPlayState:Bool = false;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);
	//var botplayText:FlxText;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();
		if (FlxG.random.bool(0.1)) exitChoices = ['Exit To Song Menu', 'Exit To Your Mother', 'Exit Game'];
		if(CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

		if (PlayState.isStoryMode && (ClientPrefs.cutscenes == 'Story Mode Only' || ClientPrefs.cutscenes == 'Always')) {
			menuItemsOG.insert(2, 'Replay Cutscene');
		} else if (!PlayState.isStoryMode && (ClientPrefs.cutscenes == 'Freeplay Only' || ClientPrefs.cutscenes == 'Always')) {
			menuItemsOG.insert(2, 'Replay Cutscene');
		}

		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG;

		for (i in 0...CoolUtil.difficulties.length) {
			var diff:String = '' + CoolUtil.difficulties[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		exitChoices.push('BACK');


		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		if (!ClientPrefs.lowQuality) {
			var bgScroll:FlxBackdrop = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll.velocity.set(19, 20); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
			bgScroll.alpha = 0;
			bgScroll.blend = BlendMode.MULTIPLY;
			add(bgScroll);
			FlxTween.tween(bgScroll, {alpha: 0.25}, 7, {
				ease: FlxEase.quadOut
			});
	
			var bgScroll2:FlxBackdrop = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll2.velocity.set(-19, -20); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
			bgScroll2.alpha = 0;
			bgScroll2.blend = BlendMode.MULTIPLY;
			add(bgScroll2);
			FlxTween.tween(bgScroll2, {alpha: 0.25}, 7, {
				ease: FlxEase.quadOut
			});
		}

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.header.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.formatStringProper(CoolUtil.difficultyString().toLowerCase());
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "", 32);
		blueballedTxt.text = "Blueballed: " + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, "Practice Mode", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, "Charting Mode", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.6, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		if (menuItems != exitChoices && menuItems != difficultyChoices) {
			updateSkipTextStuff();
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (FlxG.mouse.justPressed && ClientPrefs.mouseControls) accepted = true;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		var shiftMult:Int = 1;

		if(FlxG.mouse.wheel != 0 && ClientPrefs.mouseControls)
			{
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}

		/*if(FlxG.keys.justPressed.CONTROL)
			{
				openSubState(new GameplayChangersSubstate());
			}*/

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (accepted)
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.header.song;
					var poop = Highscore.formatSong(name, curSelected);
					#if sys
					if(sys.FileSystem.exists(Paths.modsJson(Paths.formatToSongPath(name) + '/' + poop)) || sys.FileSystem.exists(Paths.json(Paths.formatToSongPath(name) + '/' + poop))) {
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
					} else {
						trace(poop + '.json does not exist!');
						FlxG.sound.play(Paths.sound('invalidJSON'));
						FlxG.camera.shake(0.05, 0.05);
						var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!");
						funnyText.scrollFactor.set();
						funnyText.screenCenter();
						funnyText.x = FlxG.width/2 - 250;
						funnyText.y = FlxG.height/2 - 64;
						funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						add(funnyText);
						FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
							onComplete: function(tween:FlxTween)
							{
								funnyText.destroy();
							}
						});
					}
					#else
					if(OpenFlAssets.exists(Paths.json(Paths.formatToSongPath(name) + '/' + poop))) {
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
					} else {
						trace(poop + '.json does not exist!');
						FlxG.sound.play(Paths.sound('invalidJSON'));
						FlxG.camera.shake(0.05, 0.05);
						var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!");
						funnyText.scrollFactor.set();
						funnyText.screenCenter();
						funnyText.x = FlxG.width/2 - 250;
						funnyText.y = FlxG.height/2 - 64;
						funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						add(funnyText);
						FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
							onComplete: function(tween:FlxTween)
							{
								funnyText.destroy();
							}
						});
					}
					#end
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			if (menuItems == exitChoices)
			{
				if(menuItems.length - 1 != curSelected && exitChoices.contains(daSelected)) {
					switch (daSelected)
					{
						case "Exit To Song Menu":
							transferPlayState = false;
							PlayState.deathCounter = 0;
							PlayState.seenCutscene = false;
							if(PlayState.isStoryMode) {
								MusicBeatState.switchState(new StoryMenuState());
							} else {
								MusicBeatState.switchState(new FreeplayState());
							}
							FlxG.sound.playMusic(Paths.music('freakyMenu'));
							Conductor.changeBPM(100);
							PlayState.changedDifficulty = false;
							PlayState.chartingMode = false;
							PlayState.tankmanRainbow = false;
						case "Exit To Main Menu" | "Exit To Your Mother":
							transferPlayState = false;
							PlayState.deathCounter = 0;
							PlayState.seenCutscene = false;
							MusicBeatState.switchState(new MainMenuState());
							FlxG.sound.playMusic(Paths.music('freakyMenu'));
							Conductor.changeBPM(100);
							PlayState.changedDifficulty = false;
							PlayState.chartingMode = false;
							PlayState.tankmanRainbow = false;
						case "Exit Game":
							System.exit(0);
					}
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();
				case "Options Menu":
					transferPlayState = true;
					LoadingState.loadAndSwitchState(new options.OptionsState());
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
				case "Restart Song":
					restartSong();
				case "Replay Cutscene":
					PlayState.seenCutscene = false;
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case "End Song":
					transferPlayState = false;
					close();
					PlayState.instance.finishSong(true);
					PlayState.tankmanRainbow = false;
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Exit':
					menuItems = exitChoices;
					regenMenu();
				/*case "Exit to menu":
					transferPlayState = false;
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					if(PlayState.isStoryMode) {
						MusicBeatState.switchState(new StoryMenuState());
					} else {
						MusicBeatState.switchState(new FreeplayState());
					}
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					Conductor.changeBPM(100);
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					PlayState.tankmanRainbow = false;*/
			}
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.loadLoading = false;
		PlayState.instance.paused = true; // For lua
		PlayState.tankmanRainbow = false;
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));

				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item = new Alphabet(0, 70 * i + 30, menuItems[i], true, false);
			item.altRotation = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		if(skipTimeText == null) return;

		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
