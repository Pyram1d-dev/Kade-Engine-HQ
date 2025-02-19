package;

import flixel.group.FlxGroup;
import flixel.util.FlxGradient;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;

using StringTools;

class Stage // Stolen from KE 1.7 :troll:
{
	public var curStage:String = '';
	public var halloweenLevel:Bool = false;
	public var camZoom:Float;
	public var hideLastBG:Bool = false; // True = hide last BG and show ones from slowBacks on certain step, False = Toggle Visibility of BGs from SlowBacks on certain step
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String, Dynamic> = []; // Store BGs here to use them later in PlayState or when slowBacks activate
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup)
	public var layInFront:Array<Array<Dynamic>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and techincally also opponent since Haxe layering moment)
	public var slowBacks:Map<Int, Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"
	public var swagDancers:Map<String, Dynamic> = []; // Group for objects with a dance() function so that doesn't have to be manually added to beatHit in PlayState. (This is something that wasn't in KE 1.7 that I added)
	public var distractions:Array<Dynamic> = []; // Why have I complicated this whole thing
	
	public function new(stageCheck:String, songLowercase:String, daPixelZoom:Float)
	{
		curStage = stageCheck;
		camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one
		halloweenLevel = false;
		switch (stageCheck)
		{
			case 'halloween':
				{
					halloweenLevel = true;

					var hallowTex = Paths.getSparrowAtlas('halloween_bg', 'week2');

					var halloweenBG = new FlxSprite(-200, -100);
					halloweenBG.frames = hallowTex;
					halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
					halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
					halloweenBG.animation.play('idle');
					halloweenBG.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['halloweenBG'] = halloweenBG;
					toAdd.push(halloweenBG);
				}
			case 'philly':
				{

					curStage = 'philly';
					var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky', 'week3'));
					bg.scrollFactor.set(0.1, 0.1);
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city', 'week3'));
					city.scrollFactor.set(0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
					swagBacks['city'] = city;
					toAdd.push(city);

					var phillyCityLights = new FlxTypedGroup<FlxSprite>();
					distractions.push(phillyCityLights);
					//if (FlxG.save.data.distractions)
					//{
						swagGroup['phillyCityLights'] = phillyCityLights;
						toAdd.push(phillyCityLights);
					//}

					for (i in 0...5)
					{
						var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i, 'week3'));
						light.scrollFactor.set(0.3, 0.3);
						light.visible = false;
						light.setGraphicSize(Std.int(light.width * 0.85));
						light.updateHitbox();
						light.antialiasing = FlxG.save.data.antialiasing;
						phillyCityLights.add(light);
					}

					var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain', 'week3'));
					swagBacks['streetBehind'] = streetBehind;
					toAdd.push(streetBehind);

					var phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train', 'week3'));
					distractions.push(phillyCityLights);
					if (FlxG.save.data.distractions)
					{
						swagBacks['phillyTrain'] = phillyTrain;
						toAdd.push(phillyTrain);
					}

					PlayState.instance.trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes', 'week3'));
					FlxG.sound.list.add(PlayState.instance.trainSound);

					// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

					var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street', 'week3'));
					swagBacks['street'] = street;
					toAdd.push(street);
				}
			case 'limo':
				{
					camZoom = 0.90;

					var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset', 'week4'));
					skyBG.scrollFactor.set(0.1, 0.1);
					skyBG.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['skyBG'] = skyBG;
					toAdd.push(skyBG);

					var bgLimo:FlxSprite = new FlxSprite(-200, 480);
					bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo', 'week4');
					bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
					bgLimo.animation.play('drive');
					bgLimo.scrollFactor.set(0.4, 0.4);
					bgLimo.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['bgLimo'] = bgLimo;
					toAdd.push(bgLimo);

					var fastCar:FlxSprite;
					fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol', 'week4'));
					fastCar.antialiasing = FlxG.save.data.antialiasing;

					//if (FlxG.save.data.distractions)
					//{
						var grpLimoDancers = new FlxTypedGroup<Dancer>();
						toAdd.push(grpLimoDancers);
						distractions.push(grpLimoDancers);

						for (i in 0...5)
						{
							var dancer:Dancer = new Dancer((370 * i) + 130, bgLimo.y - 400, true);

							dancer.frames = Paths.getSparrowAtlas('limo/limoDancer', 'week4');
							dancer.animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
							dancer.animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
							dancer.animation.play('danceLeft');
							dancer.antialiasing = FlxG.save.data.antialiasing;
							dancer.scrollFactor.set(0.4, 0.4);
							swagDancers['bgDancer$i'] = dancer;
							grpLimoDancers.add(dancer);
						}

						swagBacks['fastCar'] = fastCar;
						layInFront[2].push(fastCar);
						distractions.push(fastCar);
					//}

					var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay', 'week4'));
					overlayShit.alpha = 0.5;
					// add(overlayShit);

					// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

					// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

					// overlayShit.shader = shaderBullshit;

					var limoTex = Paths.getSparrowAtlas('limo/limoDrive', 'week4');

					var limo = new FlxSprite(-120, 550);
					limo.frames = limoTex;
					limo.animation.addByPrefix('drive', "Limo stage", 24);
					limo.animation.play('drive');
					limo.antialiasing = FlxG.save.data.antialiasing;
					layInFront[0].push(limo);
					swagBacks['limo'] = limo;

					// Testing
					//
					// hideLastBG = true;
					// slowBacks[40] = [limo];
					// slowBacks[120] = [limo, bgLimo, skyBG, fastCar];
				}
			case 'mall':
				{
					camZoom = 0.80;

					var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls', 'week5'));
					bg.antialiasing = FlxG.save.data.antialiasing;
					bg.scrollFactor.set(0.2, 0.2);
					bg.active = false;
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var upperBoppers = new Dancer(-240, -90);
					upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop', 'week5');
					upperBoppers.animation.addByPrefix('idle', "Upper Crowd Bob", 24, false);
					upperBoppers.antialiasing = FlxG.save.data.antialiasing;
					upperBoppers.scrollFactor.set(0.33, 0.33);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					//if (FlxG.save.data.distractions)
					//{
						swagDancers['upperBoppers'] = upperBoppers;
						toAdd.push(upperBoppers);
						animatedBacks.push(upperBoppers);
					//}

					var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator', 'week5'));
					bgEscalator.antialiasing = FlxG.save.data.antialiasing;
					bgEscalator.scrollFactor.set(0.3, 0.3);
					bgEscalator.active = false;
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					swagBacks['bgEscalator'] = bgEscalator;
					toAdd.push(bgEscalator);

					var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree', 'week5'));
					tree.antialiasing = FlxG.save.data.antialiasing;
					tree.scrollFactor.set(0.40, 0.40);
					swagBacks['tree'] = tree;
					toAdd.push(tree);

					var bottomBoppers = new Dancer(-300, 140);
					bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop', 'week5');
					bottomBoppers.animation.addByPrefix('idle', 'Bottom Level Boppers', 24, false);
					bottomBoppers.antialiasing = FlxG.save.data.antialiasing;
					bottomBoppers.scrollFactor.set(0.9, 0.9);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
					//if (FlxG.save.data.distractions)
					//{
						swagDancers['bottomBoppers'] = bottomBoppers;
						toAdd.push(bottomBoppers);
						animatedBacks.push(bottomBoppers);
					//}

					var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow', 'week5'));
					fgSnow.active = false;
					fgSnow.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['fgSnow'] = fgSnow;
					toAdd.push(fgSnow);

					var santa = new Dancer(-840, 150);
					santa.frames = Paths.getSparrowAtlas('christmas/santa', 'week5');
					santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
					santa.antialiasing = FlxG.save.data.antialiasing;
					//if (FlxG.save.data.distractions)
					//{
						swagDancers['santa'] = santa;
						toAdd.push(santa);
						animatedBacks.push(santa);
					//}
				}
			case 'mallEvil':
				{
					var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG', 'week5'));
					bg.antialiasing = FlxG.save.data.antialiasing;
					bg.scrollFactor.set(0.2, 0.2);
					bg.active = false;
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree', 'week5'));
					evilTree.antialiasing = FlxG.save.data.antialiasing;
					evilTree.scrollFactor.set(0.2, 0.2);
					swagBacks['evilTree'] = evilTree;
					toAdd.push(evilTree);

					var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow", 'week5'));
					evilSnow.antialiasing = FlxG.save.data.antialiasing;
					swagBacks['evilSnow'] = evilSnow;
					toAdd.push(evilSnow);
				}
			case 'school':
				{
					curStage = 'school';
					var toLoad:Array<FlxSprite> = [];
					var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
                    bgSky.scrollFactor.set(0.1, 0.1);
                    swagBacks['bgSky'] = bgSky;
					toLoad.push(bgSky);

                    var repositionShit = -200;

					var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
                    bgStreet.scrollFactor.set(0.95, 0.95);
                    swagBacks['bgStreet'] = bgStreet;
					toLoad.push(bgStreet);

					var bgSchool:FlxSprite = new FlxSprite(repositionShit,
						0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
					bgSchool.scrollFactor.set(0.6, 0.90);
					swagBacks['bgSchool'] = bgSchool;
					toLoad.push(bgSchool);

					var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
					var treetex = Paths.getPackerAtlas('weeb/weebTrees', 'week6');
					bgTrees.frames = treetex;
					bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
					bgTrees.animation.play('treeLoop');
					bgTrees.ID = 455;
					bgTrees.scrollFactor.set(0.85, 0.85);
					swagBacks['bgTrees'] = bgTrees;
					toLoad.push(bgTrees);

					var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170,
						130).loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
					fgTrees.scrollFactor.set(0.9, 0.9);
					fgTrees.ID = 8008;
					swagBacks['fgTrees'] = fgTrees;
					toLoad.push(fgTrees);

					var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
					treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals', 'week6');
					treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
					treeLeaves.animation.play('leaves');
					treeLeaves.scrollFactor.set(0.85, 0.85);
					swagBacks['treeLeaves'] = treeLeaves;
					toLoad.push(treeLeaves);

                    var widShit = Std.int(bgSky.width * 6);

                    for (obj in toLoad)
					{
						switch (obj.ID)
                        {
							case 455:
								obj.setGraphicSize(Std.int(widShit * 1.4));
							case 8008:
								obj.setGraphicSize(Std.int(widShit * 0.8));
							default:
								obj.setGraphicSize(widShit);
                        }
						obj.updateHitbox();

						toAdd.push(obj);
					}

					var bgGirls = new Dancer(-100, 190, true);

					bgGirls.frames = Paths.getSparrowAtlas('weeb/bgFreaks', 'week6');
					bgGirls.scrollFactor.set(0.9, 0.9);
					//if (FlxG.save.data.distractions)
					//{
					if (songLowercase.startsWith('roses'))
					{
						bgGirls.animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
						bgGirls.animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
					}
					else
					{
						bgGirls.animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
						bgGirls.animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
					}
					//}
					bgGirls.animation.play('danceLeft');

                    bgGirls.visible = true;
					bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
					bgGirls.updateHitbox();
					//if (FlxG.save.data.distractions)
					//{
						swagDancers['bgGirls'] = bgGirls;
						toAdd.push(bgGirls);
					//}
				}
			case 'schoolEvil':
				{
					curStage = 'schoolEvil';

                    if (!PlayStateChangeables.Optimize)
					{
						var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
						var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
					}

					var posX = 400;
					var posY = 200;

					var bg:FlxSprite = new FlxSprite(posX, posY);
					bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool', 'week6');
					bg.animation.addByPrefix('idle', 'background 2', 24);
					bg.animation.play('idle');
					bg.scrollFactor.set(0.8, 0.9);
					bg.scale.set(6, 6);
					swagBacks['bg'] = bg;
					toAdd.push(bg);
				}

			default:
				{
					camZoom = 0.9;
					curStage = 'stage';
					var bg:FlxSprite = new FlxSprite(-600,
						-200).loadGraphic(Paths.image('stageback'));
					bg.antialiasing = FlxG.save.data.antialiasing;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					swagBacks['bg'] = bg;
					toAdd.push(bg);

					var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					stageFront.antialiasing = FlxG.save.data.antialiasing;
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.active = false;
					swagBacks['stageFront'] = stageFront;
					toAdd.push(stageFront);

					var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					stageCurtains.antialiasing = FlxG.save.data.antialiasing;
					stageCurtains.scrollFactor.set(1.3, 1.3);
					stageCurtains.active = false;

					swagBacks['stageCurtains'] = stageCurtains;
					toAdd.push(stageCurtains);
				}
		}

		for (i in swagDancers)
			distractions.push(i);

		trace(curStage);
		PlayState.curStage = curStage;
    }
}