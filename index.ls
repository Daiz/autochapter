require 'shelljs/global'
_ = require 'prelude-ls'


# constants
HOUR = 60 * 60 * 1000
MINUTE = 60 * 1000
SECOND = 1000
PARSER = /trim\((\d+),(\d+)\)/gi


# helper functions
pad = (n, m = 2) -> (s="#n").length < m and (pad "0#s" m) or s
 
time-format = (ms) ->
  hh = 0; mm = 0; ss = 0
  hh = ~~  (ms / HOUR)
  mm = ~~ ((ms - hh * HOUR) / MINUTE)
  ss = ~~ ((ms - hh * HOUR - mm * MINUTE) / SECOND)
  ms = ~~  (ms - hh * HOUR - mm * MINUTE - ss * SECOND + 0.5)
 
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

make-thumbnails = (input, opts, trims) ->
  avs = cat input

  dist = opts.lookaround
  len = dist * 2 + 1
  tlen = trims.length
  thumbs = "thumbnails.avs"

  fun = """#
  function th(clip c, frame) {
    c = c.ConvertToRGB32(matrix="Rec709").Lanczos4Resize(256,144).AssumeFPS(24)
    c = frame == 0 ? BlankClip(#dist,c.width,c.height,"RGB32",color=$00000080).KillAudio()++\\
    c.Trim(0,frame+#dist) : c.Trim(frame-#dist,frame+#dist)
    return c
    c = StackHorizontal(\\

  """

  for i from 0 til len
    fun += "  c.Trim(#i,#{i+1})"
    fun += i < len - 1 and  ",\\\n" or ")\n"

  fun += "  return c.FreezeFrame(0,1,0).Trim(1,1)\n}\n"#StackVertical("

  for t,i in trims
    fun += "th(#{t.start-frame})"
    fun += i < tlen - 1 and "++" or ""

  fun += """\nImageWriter("thumbnails\\th%01d.png",0,0,"png")"""

  (avs + fun).to thumbs
  mkdir \-p "thumbnails"
  <-! exec "avsmeter #thumbs"
  # mv \-f "thumbnails0.png" "thumbnails.png"
  rm thumbs


# default options
defaults =
  input-fps: 30000/1001
  output-fps: 24000/1001
  keyframes: void
  lookaround: 3
  template: void # if no template is specified, automatic guessing will be used
  format: \mkv # TODO: ogm chapter output
  verify: true # browser-based verification

make-chapters = (input, options, callback) ->

  # load options
  opts = defaults with options

  # find trims
  str = cat input
  |> _.lines
  |> _.find (.match PARSER)

  # generate initial trims
  trims = []; i = 0
  while trim = PARSER.exec str
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

  # do keyframe snapping if keyframes specified
  if opts.keyframes
    kfs = parse-keyframes that
    distance = [0] ++ _.flatten [[x, -x] for x from 1 to opts.lookaround]
    # generates an array like [0, 1, -1, 2, -2, 3, -3]

    for t,i in trims
      offset = (_.find (-> kfs[t.start-frame + it] is \I), distance) or 0
      t.start-frame += offset
      t.output-frames += offset
      pt = trims[i-1] if i > 0
      if pt then
        pt.end-frame += offset
        pt.output-frames += offset

  # if verification is on, generate thumbnails
  if opts.verify then make-thumbnails input, opts, trims
  # calculate actual chapter times
  for t,i in trims
    t.start-time = time-format t.start-frame * (1000ms / opts.output-fps)
    t.end-time = time-format t.end-frame * (1000ms / opts.output-fps)
    t.length-time = time-format t.output-frames * (1000ms / opts.output-fps)