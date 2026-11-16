; ---- The overlay: what runs only at the start (the front end, the level's start), packed in the
; program (ovlz) and unpacked at OVL, over the VBI's programs, the claims' last part and the patch
; program (unused till the game sets up). tools/game.sh assembles it against the program's labels
; (LBLFILE: that build's), packs it, and assembles the program again with it: the program's last,
; so nothing resident moves.
        .include LBLFILE
        * = OVL
      .if FRONTEND
        jmp attract                 ; (OVFRONT)
      .else
        rts
        nop
        nop
      .endif
        jmp levelset                ; (OVLSET)
      .if FRONTEND
        .include "front.asm"
      .endif
        .include "lvset.asm"
        .cerror * > OVLEND, "the overlay's over its room: ", * - OVLEND, " over"
