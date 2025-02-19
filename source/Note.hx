package;

import PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import haxe.Exception;

using StringTools;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var baseStrum:Float = 0;
	
	public var charterSelected:Bool = false;

	public var rStrumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var rawNoteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var originColor:Int = 0; // The sustain note's original note's color
	public var noteSection:Int = 0;

	public var isAlt:Bool = false;

	public var noteCharterObject:FlxSprite;

	public var noteScore:Float = 1;

	public var noteYOff:Int = 0;

	public var beat:Null<Float> = null;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var rating:String = "shit";

	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside Note.hx
	public var originAngle:Float = 0; // The angle the OG note of the sus note had (?)

	public var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var quantityColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, BLUE_NOTE, 2];
	public var arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var isParent:Bool = false;
	public var parent:Note = null;
	public var spotInLine:Int = 0;
	public var sustainActive:Bool = true;

	public var children:Array<Note> = [];

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inCharter:Bool = false, ?isAlt:Bool = false, ?bet:Float)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		beat = bet;

		this.isAlt = isAlt;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		if (inCharter)
		{
			this.strumTime = strumTime;
			rStrumTime = strumTime;
		}
		else
		{
			this.strumTime = strumTime;
			#if sys
			if (PlayState.isSM)
			{
				rStrumTime = strumTime;
			}
			else
				rStrumTime = (strumTime - FlxG.save.data.offset + PlayState.songOffset);
			#else
			rStrumTime = (strumTime - FlxG.save.data.offset + PlayState.songOffset);
			#end
		}


		if (this.strumTime < 0 )
			this.strumTime = 0;

		this.noteData = noteData;

		if (!inCharter)
			this.noteData%=4;

		//defaults if no noteStyle was found in chart
		var noteTypeCheck:String = 'normal';
		if (inCharter)
		{
			frames = Paths.getSparrowAtlas('NOTE_assets');

			for (i in 0...4)
			{
				animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
				animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
				animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
			}

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = FlxG.save.data.antialiasing;
		}
		else
		{
			if (PlayState.SONG.noteStyle == null)
			{
				switch (PlayState.storyWeek)
				{
					case 6:
						noteTypeCheck = 'pixel';
				}
			}
			else
			{
				noteTypeCheck = PlayState.SONG.noteStyle;
			}

			switch (noteTypeCheck)
			{
				case 'pixel':
					loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), true, 17, 17);
					if (isSustainNote)
						loadGraphic(Paths.image('weeb/pixelUI/arrowEnds', 'week6'), true, 7, 6);
					
					for (i in 0...4)
					{
						animation.add(dataColor[i] + 'Scroll', [i + 4]); // Normal notes
						animation.add(dataColor[i] + 'hold', [i]); // Holds
						animation.add(dataColor[i] + 'holdend', [i + 4]); // Tails
					}

					var widthSize = Std.int(PlayState.curStage.startsWith('school') ? (width * PlayState.daPixelZoom) : (isSustainNote ? (width * (PlayState.daPixelZoom
						- 1.5)) : (width * PlayState.daPixelZoom)));

					setGraphicSize(Math.floor(widthSize));
					updateHitbox();
				default:
					frames = Paths.getSparrowAtlas('NOTE_assets');

					for (i in 0...4)
					{
						animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
						animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
						animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
					}

					setGraphicSize(Std.int(width * 0.7));
					updateHitbox();

					antialiasing = FlxG.save.data.antialiasing;
			}
		}

		setupNote(inCharter);
	}

	public function setupNote(inCharter:Bool = false) // hoo boy hotswappable options
	{
		// x += swagWidth * noteData;
		animation.play(dataColor[noteData] + 'Scroll');
		originColor = noteData; // The note's origin color will be checked by its sustain notes
		localAngle = 0;

		switch (PlayState.SONG.noteStyle)
		{
			case 'pixel' | 'clubpenguin':
				setSize(17, 17);
				if (isSustainNote)
					setSize(7, 6);
				var widthSize = Std.int(PlayState.curStage.startsWith('school') ? (width * PlayState.daPixelZoom) : (isSustainNote ? (width * (PlayState.daPixelZoom
					- 1.5)) : (width * PlayState.daPixelZoom)));

				setGraphicSize(widthSize);
			default:
				scale.set(0.7, 0.7);
		}

		if (inCharter)
		{
			scale.set(0.7, 0.7);
			updateHitbox();
		}

		if (FlxG.save.data.stepMania && !isSustainNote)
		{
			var strumCheck:Float = rStrumTime;

			// I give up on fluctuating bpms. something has to be subtracted from strumCheck to make them look right but idk what.
			// I'd use the note's section's start time but neither the note's section nor its start time are accessible by themselves
			// strumCheck -= ???

			// Well I mean, looks like Kade figured it out in 1.7 but I'm pretty sure that requires me to use the in-game chart editor
			// so nah fuck that imma keep using SNIFF the players can cry about it ¯\_(ツ)_/¯
			// No offense to Kade's version of the chart editor but shit's kinda busted in this version and also FL is nice to use lol

			// update: LMAO I FIGURED IT OUT LET'S GO BAYBEE

			// I did fix the receptor colors in this version so they don't have to cry about that ;D

			var strumStep = (beat != null ? beat * 8 : strumCheck / (Conductor.stepCrochet / 2));

			var ind:Int = Std.int(Math.round(strumStep));

			//trace(strumStep, ind % 8);

			var col:Int = 0;
			col = quantityColor[ind % 8]; // Set the color depending on the beats

			animation.play(dataColor[col] + 'Scroll');
			localAngle -= arrowAngles[col];
			localAngle += arrowAngles[noteData];
			originAngle = localAngle;
			originColor = col;
		}

		// we make sure its downscroll and its a SUSTAIN NOTE (aka a trail, not a note)
		// and flip it so it doesn't look weird.
		// THIS DOESN'T FUCKING FLIP THE NOTE, CONTRIBUTERS DON'T JUST COMMENT THIS OUT JESUS
		// then what is this lol
		// BRO IT LITERALLY SAYS IT FLIPS IF ITS A TRAIL AND ITS DOWNSCROLL
		// ok nerd

		if (FlxG.save.data.downscroll && isSustainNote)
			flipY = true;
		else
			flipY = false;

		var stepHeight = (0.45 * Conductor.stepCrochet * FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1 ? PlayState.SONG.speed : PlayStateChangeables.scrollSpeed,
			2));

		try 
		{
			if (isSustainNote && prevNote != null)
			{
				noteScore * 0.2;
				alpha = 0.6;

				//x += width / 2;

				originColor = prevNote.originColor;
				originAngle = prevNote.originAngle;

				animation.play(dataColor[originColor] + 'holdend'); // This works both for normal colors and quantization colors
				updateHitbox();

				//x -= width / 2;

				// if (noteTypeCheck == 'pixel')
				//	x += 30;
				if (inCharter)
					x += 30;

				if (prevNote.isSustainNote)
				{
					prevNote.animation.play(dataColor[prevNote.originColor] + 'hold');
					prevNote.updateHitbox();

					prevNote.scale.y *= (stepHeight + 1) / prevNote.height; // + 1 so that there's no odd gaps as the notes scroll
					prevNote.updateHitbox();
					prevNote.noteYOff = Math.round(-prevNote.offset.y);

					prevNote.setGraphicSize();

					noteYOff = Math.round(-offset.y);
				}
			}
		}
		catch(e:Exception)
		{
			trace(e.details(), e.stack);			
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!modifiedByLua)
			angle = modAngle + localAngle;
		else
			angle = modAngle;

		if (!modifiedByLua)
		{
			if (!sustainActive)
			{
				alpha = 0.3;
			}
		}

		if (mustPress)
		{
			if (isSustainNote)
			{
				if (strumTime - Conductor.songPosition <= ((166 * Conductor.timeScale) * 0.5)
					&& strumTime - Conductor.songPosition >= (-166 * Conductor.timeScale))
					canBeHit = true;
				else
					canBeHit = false;
			}
			else
			{
				if (strumTime - Conductor.songPosition <= (166 * Conductor.timeScale)
					&& strumTime - Conductor.songPosition >= (-166 * Conductor.timeScale))
					canBeHit = true;
				else
					canBeHit = false;
			}
			if (strumTime - Conductor.songPosition < -166 && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate && !wasGoodHit)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}