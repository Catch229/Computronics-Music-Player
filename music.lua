os.loadAPI("gui")

tape = peripheral.find("tape_drive")

local tapeDrive = peripheral.find("tape_drive")

local tracks = {}
local currentTrack = 1

local modes = {"  Normal  ", "Repeat All", "Repeat One"}
local currentMode = 1

function repeatMode()
	if currentMode < 3 then
		currentMode = currentMode+1
	else
		currentMode = 1
	end
	lbl2.updateTxt(lbl2, modes[currentMode])
end

function togglePlay()
	if tapeDrive.getState() ~= "STOPPED" then
		tapeState = false -- 0 means stop
	else
		tapeState = true -- 1 means play
	end
	os.queueEvent("tape_play_toggle")
end

function fastFoward()
	if currentTrack < #tracks then
		currentTrack = currentTrack + 1
	end
	os.queueEvent("tape_change_song")
end

function rewind()
	if currentTrack > 1 then
		currentTrack = currentTrack - 1
	end
	os.queueEvent("tape_change_song")
end

function updateTapeState()
	event = os.pullEvent("tape_play_toggle")
	if tapeState then
		tape.play()
	else
		tape.stop()
	end
end

function updateTapeSong()
	event = os.pullEvent("tape_change_song")
	tape.seek(-tape.getSize())
	tape.seek(tracks[currentTrack].startpos)
end

function tapeMonitor()
	while true do
		sleep(2)
		pos = -tape.seek(-tape.getSize())
		tape.seek(pos)
		if currentMode == 3 then
			if (pos - tracks[currentTrack].startpos > tracks[currentTrack].length) then
				tape.seek(-tracks[currentTrack].length)
			end
		elseif currentMode == 2 then
			if (pos - tracks[currentTrack].startpos > tracks[currentTrack].length) and currentTrack < #tracks then
				currentTrack = currentTrack + 1
			elseif (pos - tracks[currentTrack].startpos > tracks[currentTrack].length) and currentTrack >= #tracks then
				tape.seek(-tape.getSize())
				tape.seek(tracks[1].startpos)
				currentTrack = 1
			end
		else
			if (pos - tracks[#tracks].startpos > tracks[#tracks].length) then
				tapeState = false;
				os.queueEvent("tape_play_toggle")
			end
		end
			
	end
end

function headerToTrackNames(h)
	temp = {}
	for k, v in pairs(h) do
		table.insert(temp, string.sub(v.text, 1, 18))
	end
	return temp
end

function getHeaderFromTape()
	tape.seek(-tape.getSize())
	tape.seek(1)
	local h = ""
	for i = 0, 15, 1 do
		h = h .. tape.read(128)
	end
	return textutils.unserialize(h)
end

	tape.stop()
	tape.seek(-tape.getSize())
	tape.seek(1)
	tracks = getHeaderFromTape()
	trackNames = headerToTrackNames(tracks)

	gui.createHeader("TestBox", 1, 1, gui.w)
	gui.createLine(1,gui.h,gui.w,gui.h,colors.gray)
	gui.createBtn("Play / Pause", 8, gui.h-3, togglePlay)
	gui.createBtn("RR", 2, gui.h-3, rewind)
	gui.createBtn("FF", 24, gui.h-3, fastFoward)
	gui.createBtn("Repeat", 2, gui.h-7, repeatMode)
	lbl = gui.createLabel("Repeat Mode: ", 13, gui.h-8)
	lbl2 = gui.createLabel(modes[currentMode], 14, gui.h-7)
	gui.createLine(30, 2, 30, gui.h-1, colors.black)
	songBox = gui.createScrollBox(31,2,gui.w,gui.h-1, trackNames)
	gui.drawAll()
	
	while true do	
		parallel.waitForAny(updateTapeState,gui.btnListener,tapeMonitor, updateTapeSong)
		gui.drawAll()
		
	end

