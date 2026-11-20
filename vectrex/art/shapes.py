"""
Line art for the Vectrex version: each shape is a list of polylines, in the pixels of the BBC
sprite it's drawn from (x right, y down, from the sprite's top left); a polyline of one point is a
dot. Each polyline is drawn in one go, and the beam moves with its spot off between them, so
fewer polylines means fewer blank moves.

ORIGIN is each sprite's origin (where it stands), as in the Steam version's sprite data.
"""

ORIGIN = {
    'trogg': (13, 33),
    'scrubbly': (16, 41),
}


def mirror(polys, width):
    """The shape facing the other way (width: the sprite's width in pixels)."""
    return [[(width - 1 - x, y) for x, y in p] for p in polys]


# Trogg standing, facing right (sTrogg_sr_Beeb, 26 x 34)
TROGG_SR = [
    # from his hand, up the back of his arm, over his hair, along his nose, down his front and
    # round his legs to the back of his tunic
    [(3, 22), (2, 18), (3, 13), (7, 9), (6, 7), (8, 6), (7, 3), (10, 4), (11, 1), (13, 2), (15, 0),
     (18, 1), (19, 3), (25, 4), (24, 5), (20, 6), (19, 8), (20, 12), (21, 17), (20, 21), (17, 23),
     (18, 30), (20, 32), (14, 33), (14, 27), (12, 27), (12, 31), (13, 33), (7, 33), (9, 30),
     (9, 23), (6, 22)],
    # the front of his arm, down to his hand
    [(9, 10), (6, 15), (5, 21), (3, 22)],
    # his fur tunic: over his shoulder and round the top of his tummy
    [(11, 8), (13, 15), (7, 17)],
    # his eye
    [(17, 3)],
]

# The Scrubbly (sScrubbly_Beeb, 33 x 42)
SCRUBBLY = [
    # body, from its left antenna, down its left side (with tufts), its feet, up its right side
    # and out along its right antenna
    [(8, 2), (10, 3), (12, 9), (8, 11), (5, 15), (4, 19), (1, 21), (4, 21), (3, 27), (0, 31),
     (3, 30), (4, 32), (7, 36), (6, 40), (11, 40), (12, 38), (20, 38), (21, 40), (26, 40),
     (25, 36), (28, 32), (29, 30), (32, 31), (29, 27), (28, 21), (31, 21), (28, 19), (27, 15),
     (24, 11), (20, 9), (22, 3), (24, 2)],
    # the top of its head, with the tuft in the middle
    [(12, 9), (15, 7), (16, 1), (17, 7), (20, 9)],
    # eyes (crescents, open towards the middle) and their pupils
    [(15, 17), (13, 16), (10, 17), (9, 20), (10, 22)],
    [(12, 19)],
    [(20, 19)],
    [(17, 17), (19, 16), (22, 17), (23, 20), (22, 22)],
    # mouth and fangs
    [(7, 25), (9, 26), (11, 32), (13, 26), (19, 26), (21, 32), (23, 26), (25, 25)],
]

# A gem (sGem_Beeb, 11 x 9): a cut stone, its outline and the line across its top
GEM = [[(0, 2), (2, 0), (8, 0), (10, 2), (5, 8), (0, 2), (10, 2)]]

# A key (sKey_Beeb, 22 x 10): its ring, its shaft and two teeth
KEY = [[(17, 1), (20, 1), (21, 4), (20, 8), (17, 8), (16, 4), (17, 1)],
       [(16, 4), (1, 4), (1, 8)],
       [(5, 4), (5, 7)]]
