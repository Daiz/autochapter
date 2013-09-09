require 'shelljs/global'
_ = require 'prelude-ls'

# constants
HOUR = 60 * 60 * 1000
MINUTE = 60 * 1000
SECOND = 1000

# helper functions
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

parse-keyframes = (input) ->

  # supports XviD and x264 stats files
  regex =
    xvid: /^([ipb])/i
    x264: /type:([ipb])/i

  lines = cat input |> _.lines
  mode = switch
  | /^# XviD/   == lines.0 => (lines .= slice 2) and \xvid
  | /^#options/ == lines.0 => (lines .= slice 1) and \x264

  i = 0; len = lines.length - 1; res = []
  while i < len
    if test = lines[i++].match regex[mode]
      res.push test.1.to-upper-case!

  res
  

defaults =
  input-fps: 30000/1001
  output-fps: 24000/1001
  keyframes: void
  kf-distance: 3
  template: void # if no template is specified, automatic guessing will be used
  format: \mkv # TODO: ogm chapter output

str = "Trim(567,1582)++Trim(1583,4276)++Trim(7880,29031)++Trim(31736,48215)++Trim(48216,50910)"
 
parser = /trim\((\d+),(\d+)\)/gi


make-chapters = (input, options, callback) ->

  # load options
  opts = defaults with options

  # find trims
  str = cat input
  |> _.lines
  |> _.find (.match parser)

  # generate initial trims
  trims = []; i = 0
  while trim = parser.exec str
    trims.push {start: (parse-int trim[1], 10), end: (parse-int trim[2], 10)}
    t = trims[i]
    t.input-frames = t.end - t.start + 1
    t.input-length = t.input-frames * (1000ms / opts.input-fps)
    if opts.output-fps is not opts.input-fps
      t.output-frames = Math.round t.input-length / (1000ms / opts.output-fps)
    else
      t.output-frames = t.input-frames
    t.start-frame = 0
    index = i++
    while index > 0
      t.start-frame += trims[--index].output-frames
    t.end-frame = t.start-frame + t.output-frames - 1

  # do keyframe snapping is keyframes specified
  if opts.keyframes
    kfs = parse-keyframes that
    distance = [0] ++ _.flatten [[x, -x] for x from 1 to opts.kf-distance]
    # generates an array like [0, 1, -1, 2, -2, 3, -3]

    for t,i in trims
      offset = (_.find (-> kfs[t.start-frame + it] is \I), distance) or 0
      t.start-frame += offset
      t.output-frames += offset
      pt = trims[i-1] if i > 0
      if pt then
        pt.end-frame += offset
        pt.output-frames += offset


  # calculate actual chapter times
  for t,i in trims
    t.start-time = time-format t.start-frame * (1000ms / opts.output-fps)
    t.end-time = time-format t.end-frame * (1000ms / opts.output-fps)
    t.length-time = time-format t.output-frames * (1000ms / opts.output-fps)