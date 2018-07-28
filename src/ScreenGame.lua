----------
-- @author: Sergey Pomorin
-- @skype:
----------
module(..., package.seeall);

function new()
	local localGroup = display.newGroup();
	local backGroup = display.newGroup();
	local gameGroup = display.newGroup();
	local faceGroup = display.newGroup();
	
	local ANGLE = 60;
	local SCORE = 1;
	
	local _arButtons = {};
	local _arWalls = {};
	local _arTiles = {};
	local _arPlatforms = {};
	local _bWindow = false; -- открыто окно или нет
	local _bArrow = false;
	local _bGameOver = false;
	local _character = nil;
	local _posChar = 0;
	local _arrow = nil;
	local _floorObj = nil;
	local _wndOptions = nil;
	local _wndGameOver = nil;
	local _oldTime = getTimer();
	local _timeGame = 0;
	local _countTileY = 0;
	local _countPlatformY = 6;
	local _countWall = 0;
	local _score = 0;
	local _closeTime = 0;
	local _levelTileY = 0;
	local _levelPlatformY = 0;
	local _levelWallY = 0;
	local _minCountWall = 4;
	local _speedGame = 1*scaleGraphics;
	local _offsetWallY = 800*scaleGraphics;
	local _offsetPlatformY = 700*scaleGraphics;
	local _offsetFloor = 2500*scaleGraphics;
	
	localGroup:insert(gameGroup);
	localGroup:insert(faceGroup);
	gameGroup:insert(backGroup);
	
	local rect = display.newRect( _W/2, _H/2, _W, _H )
	rect:setFillColor(0,0,0);
	backGroup:insert(rect);
	
	local tfTitle = createText("", 80*scaleGraphics, {1,1,1})
	tfTitle.x = _W/2;
	tfTitle.y = 400*scaleGraphics;
	faceGroup:insert(tfTitle);
	
	local bgScore = addObj("score");
	bgScore.xScale = 0.65*scaleGraphics;
	bgScore.yScale = bgScore.xScale;
	bgScore.x = _W/2; 
	bgScore.y = 120*scaleGraphics; 
	faceGroup:insert(bgScore);
	
	local tfScore = createText(_score, 80*scaleGraphics, {128/255,137/255,137/255})
	tfScore.x = _W/2;
	tfScore.y = 100*scaleGraphics;
	faceGroup:insert(tfScore);
	
	local function restartGame()
		_G.options_pause = false;
		localGroup:removeAllListeners();
		showGame();
	end
	
	local function closeGame()
		_G.options_pause = false;
		localGroup:removeAllListeners();
		showMenu();
	end
	
	local function closeOptions()
		if(_wndOptions)then
			_wndOptions.isVisible = false;
		end
		_G.options_pause = false;
		_closeTime = 100;
	end
	
	local function clickOptions()
		if(_bWindow)then
			return;
		end
		if(_wndOptions == nil)then
			_wndOptions = require("src.WindowOptions").new(restartGame, closeGame);
			_wndOptions.xScale = minScale*mobileScale;
			_wndOptions.yScale = _wndOptions.xScale;
			faceGroup:insert(_wndOptions);
		end
		
		_wndOptions.isVisible = true;
		_wndOptions.x = _W/2;
		_wndOptions.y = _H/2;
		
		_bWindow = true;
		_G.options_pause = true;
	end
	
	local function closeGameOver()
		if(_wndGameOver)then
			_wndGameOver.isVisible = false;
		end
		_G.options_pause = false;
		_closeTime = 100;
	end
	
	local function showGameOver()
		if(_bWindow)then
			closeOptions();
		end
		
		setItemCount("score", _score);
		if(_score> getItemCount("scoreRecord"))then
			setItemCount("scoreRecord", _score);
		end
		
		if(_wndGameOver == nil)then
			_wndGameOver = require("src.WindowGameOver").new(restartGame, closeGame);
			_wndGameOver.xScale = minScale*mobileScale;
			_wndGameOver.yScale = _wndGameOver.xScale;
			faceGroup:insert(_wndGameOver);
		end
		
		_wndGameOver.isVisible = true;
		_wndGameOver.x = _W/2;
		_wndGameOver.y = _H/2;
		
		saveData();
		
		_bWindow = true;
	end
	
	local function createBackground()
		local size = 254*scaleGraphics;
		local countX = math.ceil(_W/size) + 1;
		local countY = math.ceil(_H/size) + 1;
		local count = countX * countY;
		local posX = 0;
		local posY = _levelTileY;
		_countTileY = countY;
		
		for i=1, countY do
			local tileGroup = display.newGroup();
			posX = 0;
			
			for i=1, countX do
				local tile = addObj("tileBg");
				tile.xScale = scaleGraphics;
				tile.yScale = scaleGraphics;
				tile.w = tile.width*tile.xScale;
				tile.h = tile.height*tile.yScale;
				tile.x = tile.w*posX;
				tile.y = 0;
				tileGroup:insert(tile);
				posX = posX + 1;
			end
			tileGroup.y = tileGroup.height*posY;
			backGroup:insert(tileGroup);
			table.insert(_arTiles, tileGroup);
			posY = posY + 1;
		end
	end
	
	local function createPlatform()
		local posY = _levelPlatformY;
		
		for i=1, _countPlatformY do
			local platform = addObj("floor_0" .. i);
			scaleObjects(platform, scaleGraphics);
			platform.w = platform.width*platform.xScale;
			platform.h = platform.height*platform.yScale;
			platform.x = _W/2;
			platform.y = _H - posY*_offsetPlatformY;
			platform:setFillColor(0.5, 0.5, 0.5, 1)
			backGroup:insert(platform);
			table.insert(_arPlatforms, platform);
			posY = posY + 1;
		end
		
		_floorObj = addObj("floor");
		scaleObjects(_floorObj, scaleGraphics);
		_floorObj.w = _floorObj.width*_floorObj.xScale;
		_floorObj.h = _floorObj.height*_floorObj.yScale;
		_floorObj.x = _W/2;
		_floorObj.y = _H + _floorObj.h/2;
		backGroup:insert(_floorObj);
		
		_levelPlatformY = posY;
	end
	
	local function refreshSkinCharacter(value)
		value = tostring(value);
		_character.skin1.isVisible = false;
		_character.skin2.isVisible = false;
		_character.skin3.isVisible = false;
		_character.skin4.isVisible = false;
		_character["skin" .. value].isVisible = true;
	end
	
	local function createSkinCharacter(value)
		value = tostring(value);
		_character["skin" .. value] = addObj("character_" .. value);
		_character["skin" .. value].xScale = 0.5;
		_character["skin" .. value].yScale = _character["skin" .. value].xScale;
		_character:insert(_character["skin" .. value]);
	end
	
	local function createCharacter()
		_character = display.newGroup();
		createSkinCharacter(1);
		createSkinCharacter(2);
		createSkinCharacter(3);
		createSkinCharacter(4);
		refreshSkinCharacter(3);
		_character.xScale = 1.5*scaleGraphics;
		_character.yScale = _character.xScale;
		_character.x = _W/2;
		_character.y = _H - 600*scaleGraphics - _character.height/2;
		_character.speed = 45*scaleGraphics;
		_character.xMov = 0;
		_character.yMov = 0;
		_character.move = false;
		_character.w = _character.width*_character.xScale;
		_character.h = _character.height*_character.yScale;
		gameGroup:insert(_character);
		_floorObj.y = _character.y + _offsetFloor;
		_posChar = _character.y;
		
		if(#_arWalls > 0)then
			local wall = _arWalls[1];
			_character.x = wall.x + _character.width/2*_character.xScale;
		end
	end
	
	local function createWall()
		for i=1, 6 do
			local count = _minCountWall + math.floor(math.random()*3);
			local wall = require("src.ItemWall").new(i, count, i % 2);
			wall.xScale = scaleGraphics;
			wall.yScale = wall.xScale;
			wall.w = wall.width*wall.xScale;
			wall.h = wall.height*wall.yScale;
			wall.char = false;
			if(i % 2 == 1)then
				wall.x = wall.w/2;
			else
				wall.x = _W - wall.w/2;
			end
			wall.y = _H - (i)*_offsetWallY;
			gameGroup:insert(wall);
			table.insert(_arWalls, wall);
			
			_levelWallY = i;
		end
	end
	
	local function createArrow()
		_arrow = display.newGroup();
		local scale = scaleGraphics;
		local img = addObj("hook");
		img.xScale = -1*scale;
		img.yScale = scale;
		img.x = img.width/2*math.abs(img.xScale);
		_arrow:insert(img);
		gameGroup:insert(_arrow);
		
		_arrow.speed = 1.5;
	end
	
	local function createButtons()
		local btnPause = addButtonTexture("btnPause");
		scaleObjects(btnPause, 0.6*scaleGraphics)
		btnPause.x = _W - btnPause.w/2 - 15*scaleGraphics;
		btnPause.y = btnPause.h/2 + 15*scaleGraphics;
		localGroup:insert(btnPause)
		table.insert(_arButtons, btnPause);
	end
	
	local function refreshCharacter()
		local wall = _character.wall;
		if(wall)then
			if(wall.x > _W/2)then
				_character.x = wall.x - _character.width/2*_character.xScale;
			else
				_character.x = wall.x + _character.width/2*_character.xScale;
			end
		end
		refreshSkinCharacter(3);
		_countWall = _countWall + 1;
		
		_speedGame = math.min((1 + _countWall/10)*scaleGraphics, 10*scaleGraphics);
	end
	
	local function refreshArrow()
		if(_bGameOver)then
			return;
		end
		_arrow.x = _character.x;
		_arrow.y = _character.y;
		_arrow.isVisible = true;
		_arrow.rotation = 0;
		if(_character.x > _W/2)then
			_arrow.xScale = -1;
		else
			_arrow.xScale = 1;
			_arrow.yScale = 1;
		end
	end
	
	local function init()
		createBackground();
		createPlatform();
		createWall();
		createArrow();
		createCharacter();
		refreshArrow();
		createButtons();
	end
	
	init();
	
	local function pauseGame()
		if(options_pause)then
			closeOptions();
		else
			clickOptions();
		end
	end
	
	local function touchCharacter(event)
		if (options_pause or _bGameOver) then
			return;
		end
		
		local angle = standart.toRadians(_arrow.rotation);
		local cosAngle = math.cos(angle)*_arrow.xScale;
		local sinAngle = math.sin(angle)*_arrow.xScale;
		_character.xMov = (_character.speed)*cosAngle;
		_character.yMov = (_character.speed)*sinAngle;
		_character.move = true;
		_arrow.isVisible = false;
		refreshSkinCharacter(1);
	end
	
	local function updateTiles()
		for i=1,#_arTiles do
			local tile = _arTiles[i];
			if(_bGameOver)then
				if(tile.y + gameGroup.y <  - tile.height)then
					_levelTileY = _levelTileY + 1;
					tile.y = tile.height*_levelTileY;
				end
			else
				if(tile.y + gameGroup.y > _H + tile.height)then
					_levelTileY = _levelTileY - 1;
					tile.y = tile.height*_levelTileY;
				end
			end
		end
	end
	
	local function refreshWalls()
		for i=1,#_arWalls do
			local wall = _arWalls[i];
			wall.char = false;
		end
	end
	
	local function updateWalls()
		for i=1,#_arWalls do
			local wall = _arWalls[i];
			if(wall.y + gameGroup.y > _H + wall.h)then
				_levelWallY = _levelWallY + 1;
				if(_countWall == 15)then
					_minCountWall = 3;
				elseif(_countWall == 50)then
					_minCountWall = 2;
				end
				local count = _minCountWall + math.floor(math.random()*3);
				wall:setSize(count);
				wall.y = _H - _levelWallY*_offsetWallY;
			end
			
			if(standart.hasCollidedRect(wall.rect, _character) and 
			wall.char == false and _bGameOver == false)then
				refreshWalls();
				wall.char = true;
				_character.move = false;
				_character.wall = wall;
				refreshCharacter();
				refreshArrow();
			end
		end
	end
	
	local function updatePlatforms()
		for i=1,#_arPlatforms do
			local wall = _arPlatforms[i];
			if(_bGameOver)then
				if(wall.y + gameGroup.y < - wall.h)then
					_levelPlatformY = _levelPlatformY - 1;
					wall.y = _H - (_levelPlatformY-1)*_offsetPlatformY;
				end
			else
				if(wall.y + gameGroup.y > _H + wall.h)then
					_levelPlatformY = _levelPlatformY + 1;
					wall.y = _H - (_levelPlatformY-1)*_offsetPlatformY;
				end
			end
		end
	end
	
	local function fallCharacter()
		if (math.abs(standart.mathRound(_character.y) - _floorObj.y) > _character.h - 150*scaleGraphics)then
			_character.x = _character.x + standart.mathRound(_character.xMov);
			_character.y = _character.y + standart.mathRound(_character.yMov);
		else
			refreshSkinCharacter(4);
			showGameOver();
		end
		local _x, _y = _floorObj:localToContent(0, 0); -- localToGlobal
		if(_y > _H - _floorObj.h/2 + _character.yMov)then
			gameGroup.y = -_character.y + _posChar;
		end
	end
	
	local function gameOver()
		_bGameOver = true;
		_arrow.isVisible = false;
		_levelPlatformY = _levelPlatformY - _countPlatformY + 1;
		_levelTileY = _levelTileY + _countTileY - 1;
		refreshSkinCharacter(2);
		local angle = math.atan2((_H- 200*scaleGraphics)-(_character.y), _W/2-(_character.x));
		local cosAngle = math.cos(angle);
		local sinAngle = math.sin(angle);
		_character.xMov = (_character.speed)*cosAngle;
		_character.yMov = (_character.speed)*sinAngle;
	end
	
	local function moveCharacter()
		if(_bGameOver)then
			fallCharacter();
			return;
		end
		
		gameGroup.y = gameGroup.y + _speedGame;
		if(_character.move == false)then
			if(math.ceil(_posChar - gameGroup.y - _character.y) < -math.ceil(_H - _posChar + _character.h/2))then
				gameOver();
			end
			return;
		end
		
		_score = _score + SCORE;
		tfScore.text = _score;
		
		_character.x = _character.x + standart.mathRound(_character.xMov);
		_character.y = _character.y + standart.mathRound(_character.yMov);
		
		if(math.ceil(_posChar - gameGroup.y) < math.ceil(_character.y))then
			
		else
			gameGroup.y = -_character.y + _posChar;
			_floorObj.y = _character.y + _offsetFloor;
		end
		
		if(_character.x < _character.w/2 or _character.x > _W - _character.w/2)then
			gameOver();
		end
	end
	
	local function rotationArrow()
		if(_character.move)then
			return;
		end
	
		if(_bArrow)then
			_arrow.rotation = _arrow.rotation + _arrow.speed;
		else
			_arrow.rotation = _arrow.rotation - _arrow.speed;
		end
		
		if(_arrow.xScale == 1)then
			if(_arrow.rotation < -ANGLE)then
				_bArrow = true;
			end
			if(_arrow.rotation > -1)then
				_bArrow = false;
			end
		else
			if(_arrow.rotation < -1)then
				_bArrow = true;
			end
			if(_arrow.rotation > ANGLE)then
				_bArrow = false;
			end
		end
	end
	
	local function update()
		if (options_pause) then
			return;
		end
		
		local diffTime = getTimer() - _oldTime;
		
		_timeGame = _timeGame + diffTime;
		
		updateTiles();
		updateWalls();
		updatePlatforms();
		rotationArrow();
		moveCharacter();
		
		if(_closeTime > 0)then
			_closeTime = _closeTime - diffTime;
			if(_closeTime < 1)then
				_bWindow = false;
			end
		end
		
		_oldTime = getTimer();
	end
	
	-------------- touchHandler ----------------
	local function checkButtons(event)
		if(_bWindow)then
			-- return;
		end
		for i=1,#_arButtons do
			local item_mc = _arButtons[i];
			local _x, _y = item_mc:localToContent(0, 0); -- localToGlobal
			local dx = event.x - _x;
			local dy = event.y - _y;
			local w = item_mc.w;
			local h = item_mc.h;

			if(math.abs(dx)<w/2 and math.abs(dy)<h/2 and item_mc.isVisible)then
				if(item_mc._selected and event.isPrimaryButtonDown)then
					if(item_mc.img)then
						item_mc.img:stopAtFrame(2);
					end
				elseif(item_mc._selected == false)then
					item_mc._selected = true;
					if(item_mc._over)then
						item_mc._over.alpha = 0.3;
					elseif(item_mc.img)then
						item_mc.img:stopAtFrame(2);
					end
				end
			else
				if(item_mc._selected)then
					item_mc._selected = false;
					if(item_mc._over)then
						item_mc._over.alpha = 0;
					elseif(item_mc.img)then
						item_mc.img:stopAtFrame(1);
					end
				end
			end
		end
	end
	
	local function touchHandler(event)
		local phase = event.phase;
		if(phase=='began')then
			checkButtons(event);
		elseif(phase=='moved')then
			checkButtons(event);
		else
			for i=1,#_arButtons do
				local item_mc = _arButtons[i];
				if(item_mc._selected)then
					item_mc._selected = false;
					if(item_mc._over)then
						item_mc._over.alpha = 0;
					elseif(item_mc.img)then
						item_mc.img:stopAtFrame(1);
						if(item_mc.tf)then
							item_mc.tf.y = item_mc.tf.tgY;
						end
					end
					if(item_mc.onRelease)then
						item_mc:onRelease();
						soundPlay("click_approve");
						return true;
					elseif(item_mc.act == "btnPause")then
						soundPlay("click_approve");
						pauseGame();
						return true;
					end
				end
			end
			
			touchCharacter(event);
		end
	end
	
	local function onKeyEvent(event)
		local phase = event.phase
		local keyName = event.keyName
		local nativeKeyCode = event.nativeKeyCode;
		local isShiftDown = event.isShiftDown;
		if(phase == 'up') then
			if(keyName == "escape" or keyName == "back") then
				if(_bWindow)then
					if(_wndOptions and _wndOptions.isVisible)then
						closeOptions();
						return true;
					end
				else
					if(_wndOptions and _wndOptions.isVisible == false)then
						clickOptions();
						return true;
					end
				end
			end
		end
		return false;
	end
	
	function localGroup:removeAllListeners()
		Runtime:removeEventListener( "enterFrame", update );
		Runtime:removeEventListener("touch", touchHandler);
		Runtime:removeEventListener( "key", onKeyEvent )
		if(_wndOptions)then
			_wndOptions:removeAllListeners();
			_wndOptions = nil;
		end
		if(_wndGameOver)then
			_wndGameOver:removeAllListeners();
			_wndGameOver = nil;
		end
	end
	
	Runtime:addEventListener( "enterFrame", update );
	Runtime:addEventListener( "touch", touchHandler );
	Runtime:addEventListener( "key", onKeyEvent )
	
	return localGroup;
end