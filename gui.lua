local w, h = term.getSize()
local btns = {}
local lbls = {}
local hdrs = {}
local lns = {}
local scrollboxes = {}
local wCenter = w/2
local hCetner = h/2

--Convience functions
function theme(themeBase)
	themes = {
		headerFG = colors.white,
		headerBG = colors.gray,
		textFG = colors.gray,
		textBG = colors.white,
		buttonFG = colors.white,
		buttonBG = colors.blue,
		labelFG = colors.black,
		labelBG = colors.white,
		screenBG = colors.white,
		screenFG = colors.white
	}
	
	term.setBackgroundColor(themes[themeBase.."BG"])
	term.setTextColor(themes[themeBase.."FG"])
end

-- FUNCTIONS TO CREATE GUI ELEMENTS
--Button
function createBtn(iText, iXpos, iYpos, iFunc, iParent)
	iParent = iParent or nil
	local temp = {}
	temp.text = iText
	temp.xpos = iXpos 
	temp.ypos = iYpos
	temp.func = iFunc
	temp.parent = iParent
	table.insert(btns, temp)
	return temp
end

--Label
function createLabel(iText, iXpos, iYpos, iWidth, iColor, iTColor)
	iColor = iColor or colors.white
	iTColor = iTColor or colors.black
	iWidth = iWidth or 1
	local temp = {}
	temp.text = iText
	temp.xpos = iXpos 
	temp.ypos = iYpos
	temp.width = iWidth
	temp.color = iColor
	temp.t_color = iTColor
	function temp.updateTxt(self, iText)
		self.text = iText
	end
	table.insert(lbls, temp)
	return temp
end

--Header
function createHeader(iText, iXpos, iYpos, iWidth)
	local temp = {}
	temp.text = iText
	temp.xpos = iXpos 
	temp.ypos = iYpos
	temp.width = iWidth
	function temp.updateTxt(self, iText)
		self.text = iText
	end
	table.insert(hdrs, temp)
	return temp
end

--Line
function createLine(iX1, iY1, iX2, iY2, iColor)
	local temp = {}
	temp.x1 = iX1
	temp.y1 = iY1
	temp.x2 = iX2
	temp.y2 = iY2
	temp.color = iColor
	table.insert(lns, temp)
	
	return temp
end

--Scrollbox
function createScrollBox(iX1, iY1, iX2,iY2, iData)
	local temp = {}
	temp.scrollPos = 1
	temp.data = iData
	temp.labels = {}
	for i = iY1, iY2, 1 do
		if i%2 == 0 then --Alternate colors for apperance
			color = colors.lightGray
		else
			color = colors.white
		end
		sLbl = createLabel(nil, iX1, i, (iX2-iX1)-2, color, colors.black)
		table.insert(temp.labels, sLbl)
	end
	function temp.scrollBoxDown(self)
		if (#self.data > #self.labels and self.scrollPos < (#self.data - #self.labels+1)) then
			self.scrollPos = self.scrollPos + 1
			self.updateLabels(self)
		end
	end
	function temp.scrollBoxUp(self)
		if (#self.data > #self.labels and self.scrollPos > 1) then
			self.scrollPos = self.scrollPos - 1
			self.updateLabels(self)
		end
	end
	function temp.updateLabels(self) --Update which data from array is shown on labels. Requires redraw
		for i = 1, #self.labels, 1 do
			self.labels[i].updateTxt(self.labels[i],self.data[i+self.scrollPos-1])
		end
	end
	function temp.updateData(self, iData) --Function to change the data array
		self.data = iData
	end
	temp.up = createBtn("^", iX2-1, iY1+1, temp.scrollBoxUp, temp) --Create scrolling buttons
	temp.down = createBtn("v", iX2-1, iY2-1, temp.scrollBoxDown, temp)
	table.insert(scrollboxes, temp)
	return temp
end

--DRAWING FUNCTIONS
--Draws lines using builtin function. Its useful to store line data for later use and simple redraws
function drawLines()
	for k, v in pairs(lns) do
		paintutils.drawLine(v.x1, v.y1, v.x2, v.y2, v.color)
	end
end
	
function doSomething()
	print("Shit")
end

--Draws all elements including lines. This function should be called each time the display should update.
function drawAll()
	--UPDATE SCREEN COLOR
	theme("screen")
	term.clear()
	--DRAW SCROLLBOXES
	for k, v in pairs(scrollboxes) do
	v.updateLabels(v)
	end
	--DRAW BUTTONS
	theme("button")
	for k, v in pairs(btns) do
	for i=0, #v.text+1, 1 do
		term.setCursorPos(v.xpos+i, v.ypos-1)
		print(" ")
		term.setCursorPos(v.xpos+i, v.ypos+1)
		print(" ")
	end
	term.setCursorPos(v.xpos, v.ypos)
	print(" "..v.text.." ")
	end
	--DRAW LABELS
	for k, v in pairs(lbls) do
	tString = " "..v.text
	for i = 0, v.width-(#tostring(v.text)+1), 1 do
		tString = tString.." "
	end
	term.setTextColor(v.t_color)
	term.setBackgroundColor(v.color)
	term.setCursorPos(v.xpos, v.ypos)
	print(tString)
	end
	--DRAW HEADERS
	theme("header")
	for k, v in pairs(hdrs) do
	for i=0, v.width, 1 do
		term.setCursorPos(v.xpos+i, v.ypos)
		print(" ")
	end
	term.setCursorPos(v.xpos+(v.width/2)-(#v.text/2), v.ypos)
	print(" "..v.text.." ")
	end
	--DRAW LINES
	drawLines()

end

--BTN LISTENER RUNS FUNCTIONS LINKED TO INDIVIDUAL BUTTONS

function btnListener()
	local event, mBtn, mX, mY = os.pullEvent("mouse_click")
	if mBtn == 1 then
	for k, v in pairs(btns) do
		if (mX >= v.xpos - 1) and (mX <= v.xpos + #v.text + 1) and (mY >= v.ypos - 1) and (mY <= v.ypos + 1) then
		term.setTextColor(colors.red)
		if v.parent then	--IF STATEMENT CHECKS IF BUTTON CLICK IS PART OF ANOTHER CONTROL ELEMENT
			v.func(v.parent)
			drawAll()
		else
			v.func()
		end
		end
	end
	end
end