require 'shelljs/global'
_ = require 'prelude-ls'

# impure function - (sync) IO side effects
make-thumbnails = (trims, opts) ->
  avs = opts.input

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

  fun += "  return c.FreezeFrame(0,1,0).Trim(1,1)\n}\n"

  for t,i in trims
    fun += "th(#{t.start-frame})"
    fun += i < tlen - 1 and "++" or ""

  fun += """\nImageWriter("thumbnails\\th%01d.png",0,0,"png")"""

  (avs + fun).to thumbs
  mkdir \-p "contents/thumbnails"
  <-! exec "avsmeter #thumbs"
  rm thumbs

verify = (^^trims, ^^opts, callback) ->
  if not opts.verify then return callback trims

  make-thumbnails trims, opts


module.exports = verify