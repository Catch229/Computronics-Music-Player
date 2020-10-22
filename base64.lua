local tape = peripheral.find("tape_drive")
if not tape then
  print("This program requires a tape drive to run.")
  return
end

function confirm(msg)
  term.clear()
  term.setCursorPos(1,1)
  print(msg)
  print("Type `y` to confirm, `n` to cancel.")
  repeat
    local response = read()
    if response and response:lower():sub(1, 1) == "n" then
      print("Canceled.")
      return false
    end
  until response and response:lower():sub(1, 1) == "y"
  return true
end

function writeTape(songByte)
  local msg, _, y, success
  local block = 8192 --How much to read at a time
 
  if not confirm("Are you sure you want to write to this tape?") then return end
  tape.stop()
  tape.seek(-tape.getSize())
  tape.stop() --Just making sure
 
  local bytery = 0 --For the progress indicator
  local filesize = #songByte

  print("Writing...")
 
  _, y = term.getCursorPos()
 
  if filesize > tape.getSize() then
    term.setCursorPos(1, y)
    printError("Error: File is too large for tape, shortening file")
    _, y = term.getCursorPos()
    filesize = tape.getSize()
  end
 
  repeat
    local bytes = {}
    for i = 1, block do
      local byte = songByte[bytery + i]
      if not byte then break end
      bytes[#bytes + 1] = byte
    end
    if #bytes > 0 then
      if not tape.isReady() then
        io.stderr:write("\nError: Tape was removed during writing.\n")
        return
      end
      term.setCursorPos(1, y)
      bytery = bytery + #bytes
      term.write("Read " .. tostring(math.min(bytery, filesize)) .. " of " .. tostring(filesize) .. " bytes...")
      for i = 1, #bytes do
        tape.write(bytes[i])
      end
      sleep(0)
    end
  until not bytes or #bytes <= 0 or bytery > filesize
  tape.stop()
  tape.seek(-tape.getSize())
  tape.stop() --Just making sure
  print("\nDone.")
end

function lsh(value,shift)
    return (value*(2^shift)) % 256
end
function rsh(value,shift)
    return math.floor(value/2^shift) % 256
end
function cBit(x,b)
    return (x % 2^b - x % 2^(b-1) > 0)
end
function lor(x,y)
    result = 0
    for p=1,8 do result = result + (((cBit(x,p) or cBit(y,p)) == true) and 2^(p-1) or 0) end
    return result
end
 
-- Encoding
local base64chars = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='+',[63]='/'}
function encode(inFile)
    local bytes = {}
    local result = ""
    inputFile = fs.open(inFile, "rb")
    outFile = fs.open(inFile .. ".b64", "w")
    for spos=0,fs.getSize(inFile)-1,3 do
        for byte=1,3 do bytes[byte] = inputFile.read() or 0 end
        outFile.write(string.format('%s%s%s%s',base64chars[rsh(bytes[1],2)],base64chars[lor(lsh((bytes[1] % 4),4), rsh(bytes[2],4))] or "=",((fs.getSize(inFile)-spos) > 1) and base64chars[lor(lsh(bytes[2] % 16,2), rsh(bytes[3],6))] or "=",((fs.getSize(inFile)-spos) > 2) and base64chars[(bytes[3] % 64)] or "="))
        
		
		if spos%27000 == 0 then
			os.queueEvent("randomEvent")
        	os.pullEvent()
			term.clear()
			term.setCursorPos(1,1)
			print(math.floor(spos/fs.getSize(inFile)*100) .. "% encoded...")
		end
    end
    outFile.close()
    inputFile.close()
    return result
end
 
-- Decoding
local base64bytes = {['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['+']=62,['/']=63,['=']=nil}
function decode(pasteBinID)
	local bytes = {}
    local chars = {}
    local result=""
    local songHandle = http.get("https://pastebin.com/raw/" .. pasteBinID)
	local data = songHandle.readAll()

    for dpos=0,string.len(data)-1,4 do
        for char=1,4 do
            chars[char] = (base64bytes[(string.sub(data,(dpos+char),(dpos+char)) or "=")])
        end
		
		bytes[#bytes + 1] = (lor(lsh(chars[1], 2), rsh(chars[2], 4)))
		bytes[#bytes + 1] = ((chars[3] ~= nil) and lor(lsh(chars[2], 4), rsh(chars[3], 2)) or "")
		bytes[#bytes + 1] = ((chars[4] ~= nil) and lor(lsh(chars[3], 6), (chars[4])) or "")
       
        
		
		if dpos%32000 == 0 then
			os.queueEvent("randomEvent")
       		os.pullEvent()
			term.clear()
			term.setCursorPos(1,1)
			print(math.floor(dpos/string.len(data)*100) .. "% decoded...")
		end
       
    end
	writeTape(bytes)
    return result
end
 
tArgs = {...}
EorD = tArgs[1]
tBE = tArgs[2]
if not EorD or not tBE then
    print("Usage: Base64 <-E:-D> <FileName:PasteBinID>")
else 
	if EorD == "-E" or EorD == "-e" then
		if fs.exists(tBE) then
			encoded = encode(tBE)
			print("Original File: "..tBE.." | Encoded File: "..tBE..".b64")
		else
			error("File "..tBE.." Doesn't Exist")
		end
	elseif EorD == "-D" or EorD == "-d" then
		decoded = decode(tBE)
		print("Pastebin Link: "..tBE.." written to tape!")
	else
		error("I don't understand: "..EorD)
	end
end