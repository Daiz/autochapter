HOUR = 60 * 60 * 1000
MINUTE = 60 * 1000
SECOND = 1000

pad = (n, m = 2) -> (s="#n").length < m and (pad "0#s" m) or s
 
time-format = (ms) ->
  hh = 0; mm = 0; ss = 0
  while ms > HOUR
    hh++; ms -= HOUR
  while ms > MINUTE
    mm++; ms -= MINUTE
  while ms > SECOND
    ss++; ms -= SECOND
  ms = Math.round ms
 
  "#{pad hh}:#{pad mm}:#{pad ss}.#{pad ms, 3}"

input-fps = 30000/1001
output-fps = 24000/1001
 
str = "Trim(567,1582)++Trim(1583,4276)++Trim(7880,29031)++Trim(31736,48215)++Trim(48216,50910)"
 
parser = /trim\((\d+),(\d+)\)/gi
trims = []; i = 0
 
while trim = parser.exec str
  trims.push {start: (parse-int trim[1], 10), end: (parse-int trim[2], 10)}
  t = trims[i]
  t.input-frames = t.end - t.start + 1
  t.length = t.input-frames * (1000ms / input-fps)
  if output-fps is not input-fps
    t.output-frames = Math.round t.length / (1000ms / output-fps)
  else
    t.output-frames = t.input-frames
  t.start-frame = 0
  index = i++
  while index > 0
    t.start-frame += trims[--index].output-frames
  t.end-frame = t.start-frame + t.output-frames - 1
  t.start-time = t.start-frame * (1000ms / output-fps)
  t.end-time = t.end-frame * (1000ms / output-fps)
  "#{t.start-frame}-#{t.end-frame}: #{time-format t.start-time}"