# 7sProMax physical key -> matrix (row, col) mapping (real-machine ID in progress)

Test keymap: each matrix position outputs a distinct key.
Left half positions: index = row*8 + col (rows 0-4). Right: rows 5-9.

## Left half

| physical row | pressed order -> outputs | matrix assignment |
|---|---|---|
| ESC row (top) | 1 2 3 4 5 6 | (0,0)=N1 (0,1)=N2 (0,2)=N3 (0,3)=N4 (0,4)=N5 (0,5)=N6 |
| Tab row | 9 0 Q W E R | (1,0)=N9 (1,1)=N0 (1,2)=Q (1,3)=W (1,4)=E (1,5)=R |
| CapsLock row | U I O P A S | (2,0)=U (2,1)=I (2,2)=O (2,3)=P (2,4)=A (2,5)=S |
| Shift row | (Shift: NO output) H J K L Z | letters = (3,1)=H (3,2)=J (3,3)=K (3,4)=L (3,5)=Z |
| Bottom row | (key1: NO output) B N M | key1 = (4,0) [&mo 1 in test keymap -> silent by design], B=(4,2) N=(4,3) M=(4,4) |

Left-half status after all 28 MX keys pressed (6/6/6/6/4):
- Rows 0-2 fully identified, row-major, left-to-right.
- Bottom row key1 = (4,0): the &mo 1 hypothesis moved here from Shift;
  this was the original assumption and it fits (silent by design).
- RESOLVED 2026-11-23: Shift = (3,0). The switch itself was faulty;
  after swapping it, G is output as expected. Left MX 28 keys all
  identified; rows are row-major, columns left-to-right, no surprises.
- Tact switches (2026-11-23): outputs 8, Y, F in the order pressed
  -> (0,7)=N8, (1,7)=Y, (2,7)=F. The tacts form the col-7 column of
  rows 0-2. Physical tact order vs. these three: pressed in a line,
  starting end to be confirmed by the user.
- LEFT HALF COMPLETE: 28 MX + 3 tact = 31 positions identified.
  Remaining 9 positions are unpopulated: (0,6) (1,6) (2,6) (3,6)
  (3,7) (4,1) (4,5) (4,6) (4,7). 31 + 9 = 40 = full 5x8 matrix.

Interim conclusion: physical rows match matrix rows top-to-bottom,
columns run left-to-right. Row-major assumption holds so far.

## Right half (reported bottom row first)

Test keymap right rows: row5: F1-F8 / row6: F9 F10 F11 F12 GRAVE MINUS
EQUAL BSLH / row7: LBKT RBKT SEMI SQT HOME END PG_UP PG_DN /
row8: KP_N1..KP_N8 / row9: KP_N9 KP_N0 KP_DOT KP_ENTER KP_PLUS
KP_MINUS KP_MULTIPLY &mo 1.

| physical row | pressed order -> outputs | matrix assignment |
|---|---|---|
| Bottom row | 9 0 Enter Plus | (9,0)=KP_N9 (9,1)=KP_N0 (9,3)=KP_ENTER (9,4)=KP_PLUS; gap at (9,2) |
| 2nd from bottom | 1 2 3 4 5 6 7 | (8,0)..(8,6)=KP_N1..KP_N7 |
| Middle row | @ [ ; : Home (silent) PgUp | (7,0)=LBKT (7,1)=RBKT (7,2)=SEMI (7,3)=SQT (7,4)=HOME (7,5)=END (7,6)=PG_UP |

Notes on the middle row: the host uses a JIS layout, so LBKT shows as
"@" and RBKT as "["; SQT shows as ":". The "silent" key between Home
and PgUp is (7,5)=END -- End produces no visible change in a chat
input already at the end of the text, so this is by position, not a
fault. Row 7 has 7 keys in this band; (7,7)=PG_DN lives in the 2nd
band (see below).

## Right half top rows + tacts (2026-11-23, keyboard-tester.com)

| physical row | pressed order -> outputs | matrix assignment |
|---|---|---|
| Top row (9 keys) | F1 F2 F3 F4 F5 F6 F7 F8 Yen | (5,0)..(5,7)=F1..F8, 9th key = (6,7)=BSLH (JIS Yen) |
| 2nd row (8 keys) | F9 F10 F11 F12 ` - = PgDn | (6,0)=F9 (6,1)=F10 (6,2)=F11 (6,3)=F12 (6,4)=GRAVE (6,5)=MINUS (6,6)=EQUAL (6,7 is in the top band) (7,7)=PG_DN; EQUAL confirmed present 2026-11-24 (it was simply missed in the first pass) |
| Tact switches (left->right) | KPSubtract KPMultiply (silent) | (9,5)=KP_MINUS (9,6)=KP_MULTIPLY (9,7)=&mo 1 (silent by design) |

Band structure (right half): each physical band is one matrix row,
with the NEXT row's col-7 key spilling into the band above it:
top band = row 5 (8 keys) + (6,7); 2nd band = row 6 cols 0-6 +
(7,7); middle band = row 7 cols 0-6; 4th band = row 8 cols 0-6;
bottom band = row 9 cols 0,1,3,4 (MX) and row 9 cols 5,6,7 are the
three tact switches.

- RIGHT HALF: 35 MX + 3 tact = 38 positions identified.
  Remaining 2 positions are unpopulated:
  (8,7)=KP_N8, (9,2)=KP_DOT. 38 + 2 = 40 = full 5x8 matrix.
- BOTH HALVES FULLY MAPPED (2026-11-24). The draft matrix transform
  (row-offset 5) needs no change; the real keymap just assigns
  keycodes per this physical map.
