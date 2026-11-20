; made by vectrex/tools/m1_zigp_gen.py

; a multi-pass zigzag: 1 passes, drift 3
zp_trogg_1
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FD                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -3
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                sty     <VIA_port_b             ;  6 t = 64: row 1
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                sty     <VIA_port_b             ;  6 t = 192: row 3
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 5
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                sty     <VIA_port_b             ;  6 t = 448: row 7
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                sty     <VIA_port_b             ;  6 t = 576: row 9
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                sty     <VIA_port_b             ;  6 t = 704: row 11
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                stu     <VIA_port_b             ;  5 t = 768: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                sty     <VIA_port_b             ;  6 t = 832: row 13
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                stu     <VIA_port_b             ;  5 t = 896: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                ldb     ,x+                     ;  6 t = 912: byte 57
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                sty     <VIA_port_b             ;  6 t = 960: row 15
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                stu     <VIA_port_b             ;  5 t = 1024: row 16
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                sty     <VIA_port_b             ;  6 t = 1088: row 17
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                stu     <VIA_port_b             ;  5 t = 1152: row 18
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                sty     <VIA_port_b             ;  6 t = 1216: row 19
                ldb     ,x+                     ;  6 t = 1222: byte 77
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                stu     <VIA_port_b             ;  5 t = 1280: row 20
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                sty     <VIA_port_b             ;  6 t = 1344: row 21
                ldb     ,x+                     ;  6 t = 1350: byte 85
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                lda     ,x+                     ;  6 t = 1360: byte 86
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                stu     <VIA_port_b             ;  5 t = 1408: row 22
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                ldb     ,x+                     ;  6 t = 1424: byte 89
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                ldb     ,x+                     ;  6 t = 1440: byte 91
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                lda     ,x+                     ;  6 t = 1456: byte 92
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                sty     <VIA_port_b             ;  6 t = 1472: row 23
                ldb     ,x+                     ;  6 t = 1478: byte 93
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                lda     ,x+                     ;  6 t = 1488: byte 94
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                stu     <VIA_port_b             ;  5 t = 1536: row 24
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                ldb     ,x+                     ;  6 t = 1552: byte 97
                lda     ,x+                     ;  6 t = 1558: byte 98
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                sty     <VIA_port_b             ;  6 t = 1600: row 25
                ldb     ,x+                     ;  6 t = 1606: byte 101
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                lda     ,x+                     ;  6 t = 1616: byte 102
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                stu     <VIA_port_b             ;  5 t = 1664: row 26
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                ldb     ,x+                     ;  6 t = 1680: byte 105
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                sty     <VIA_port_b             ;  6 t = 1728: row 27
                ldb     ,x+                     ;  6 t = 1734: byte 109
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                lda     ,x+                     ;  6 t = 1744: byte 110
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                ldb     ,x+                     ;  6 t = 1760: byte 111
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                lda     ,x+                     ;  6 t = 1776: byte 112
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                stu     <VIA_port_b             ;  5 t = 1792: row 28
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                ldb     ,x+                     ;  6 t = 1808: byte 113
                lda     ,x+                     ;  6 t = 1814: byte 114
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                ldb     ,x+                     ;  6 t = 1824: byte 115
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                lda     ,x+                     ;  6 t = 1840: byte 116
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1859: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 2 passes, drift 5
zp_trogg_2
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FB                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -5
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                sty     <VIA_port_b             ;  6 t = 64: row 1
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                sty     <VIA_port_b             ;  6 t = 192: row 3
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 5
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                sty     <VIA_port_b             ;  6 t = 448: row 7
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                sty     <VIA_port_b             ;  6 t = 576: row 9
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                sty     <VIA_port_b             ;  6 t = 704: row 11
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                stu     <VIA_port_b             ;  5 t = 768: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                sty     <VIA_port_b             ;  6 t = 832: row 13
                ldb     ,x+                     ;  6 t = 838: byte 53
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                stu     <VIA_port_b             ;  5 t = 896: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                ldb     ,x+                     ;  6 t = 912: byte 57
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                sty     <VIA_port_b             ;  6 t = 960: row 15
                ldb     ,x+                     ;  6 t = 966: byte 61
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                stu     <VIA_port_b             ;  5 t = 1024: row 16
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                ldb     ,x+                     ;  6 t = 1040: byte 65
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                sty     <VIA_port_b             ;  6 t = 1088: row 17
                ldb     ,x+                     ;  6 t = 1094: byte 69
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1123: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting left
                ldy     #$8005                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 5
                ldu     #$01B0                  ;  3 (the sample-and-hold settles)
                ldy     #$0150                  ;  4 
                ldd     #$81B0                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed -80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 99: row 2
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 163: row 3
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 227: row 4
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 291: row 5
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 355: row 6
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 419: row 7
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 483: row 8
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 547: row 9
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                ldb     ,x+                     ;  6 t = 560: byte 35
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 611: row 10
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 675: row 11
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 739: row 12
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                ldb     ,x+                     ;  6 t = 752: byte 47
                lda     ,x+                     ;  6 t = 758: byte 48
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 803: row 13
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                ldb     ,x+                     ;  6 t = 816: byte 51
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 867: row 14
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                ldb     ,x+                     ;  6 t = 880: byte 55
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 931: row 15
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                ldb     ,x+                     ;  6 t = 944: byte 59
                lda     ,x+                     ;  6 t = 950: byte 60
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 995: row 16
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                ldb     ,x+                     ;  6 t = 1008: byte 63
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1059: row 17
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1123: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 3 passes, drift 8
zp_trogg_3
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80F8                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -8
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                sty     <VIA_port_b             ;  6 t = 64: row 1
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                stu     <VIA_port_b             ;  5 t = 128: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                sty     <VIA_port_b             ;  6 t = 192: row 3
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 5
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                sty     <VIA_port_b             ;  6 t = 448: row 7
                ldb     ,x+                     ;  6 t = 454: byte 29
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                stu     <VIA_port_b             ;  5 t = 512: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                sty     <VIA_port_b             ;  6 t = 576: row 9
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 675: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting right
                ldy     #$8008                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 8
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 99: row 2
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 163: row 3
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 227: row 4
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 291: row 5
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 355: row 6
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 419: row 7
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 483: row 8
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 547: row 9
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                ldb     ,x+                     ;  6 t = 560: byte 35
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 611: row 10
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 659: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                clr     <VIA_shift_reg          ;  6 spot off
; pass 2: down, starting right
                ldy     #$80F8                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -8
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                stu     <VIA_port_b             ;  5 t = 80: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                stu     <VIA_port_b             ;  5 t = 208: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                sty     <VIA_port_b             ;  6 t = 272: row 5
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                stu     <VIA_port_b             ;  5 t = 336: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                lda     ,x+                     ;  6 t = 352: byte 22
                ldb     ,x+                     ;  6 t = 358: byte 23
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 7
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                stu     <VIA_port_b             ;  5 t = 464: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 9
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                stu     <VIA_port_b             ;  5 t = 592: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                lda     ,x+                     ;  6 t = 608: byte 38
                ldb     ,x+                     ;  6 t = 614: byte 39
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                sty     <VIA_port_b             ;  6 t = 656: row 11
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 723: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 1 passes, drift 2
zp_scrubbly_1
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FE                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -2
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80: row 1
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 3
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 5
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                sty     <VIA_port_b             ;  6 t = 560: row 7
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 9
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                stu     <VIA_port_b             ;  5 t = 800: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                ldb     ,x+                     ;  6 t = 816: byte 51
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                sty     <VIA_port_b             ;  6 t = 880: row 11
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                sty     <VIA_port_b             ;  6 t = 1040: row 13
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                stu     <VIA_port_b             ;  5 t = 1120: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldb     ,x+                     ;  6 t = 1136: byte 71
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldb     ,x+                     ;  6 t = 1152: byte 73
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                lda     ,x+                     ;  6 t = 1168: byte 74
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                sty     <VIA_port_b             ;  6 t = 1200: row 15
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                stu     <VIA_port_b             ;  5 t = 1280: row 16
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                ldb     ,x+                     ;  6 t = 1344: byte 85
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                sty     <VIA_port_b             ;  6 t = 1360: row 17
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                ldb     ,x+                     ;  6 t = 1408: byte 89
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                lda     ,x+                     ;  6 t = 1424: byte 90
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                stu     <VIA_port_b             ;  5 t = 1440: row 18
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                ldb     ,x+                     ;  6 t = 1456: byte 91
                lda     ,x+                     ;  6 t = 1462: byte 92
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                lda     ,x+                     ;  6 t = 1488: byte 94
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                sty     <VIA_port_b             ;  6 t = 1520: row 19
                lda     ,x+                     ;  6 t = 1526: byte 96
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                ldb     ,x+                     ;  6 t = 1536: byte 97
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                lda     ,x+                     ;  6 t = 1552: byte 98
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                stu     <VIA_port_b             ;  5 t = 1600: row 20
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                ldb     ,x+                     ;  6 t = 1616: byte 101
                lda     ,x+                     ;  6 t = 1622: byte 102
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                ldb     ,x+                     ;  6 t = 1664: byte 105
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                sty     <VIA_port_b             ;  6 t = 1680: row 21
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldb     ,x+                     ;  6 t = 1728: byte 109
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                lda     ,x+                     ;  6 t = 1744: byte 110
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                stu     <VIA_port_b             ;  5 t = 1760: row 22
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                ldb     ,x+                     ;  6 t = 1776: byte 111
                lda     ,x+                     ;  6 t = 1782: byte 112
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                ldb     ,x+                     ;  6 t = 1792: byte 113
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1804: byte 112
                lda     ,x+                     ;  6 t = 1808: byte 114
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1820: byte 113
                ldb     ,x+                     ;  6 t = 1824: byte 115
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1836: byte 114
                sty     <VIA_port_b             ;  6 t = 1840: row 23
                lda     ,x+                     ;  6 t = 1846: byte 116
                stb     <VIA_shift_reg          ;  4 t = 1852: byte 115
                ldb     ,x+                     ;  6 t = 1856: byte 117
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1868: byte 116
                lda     ,x+                     ;  6 t = 1872: byte 118
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1884: byte 117
                ldb     ,x+                     ;  6 t = 1888: byte 119
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1900: byte 118
                lda     ,x+                     ;  6 t = 1904: byte 120
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1916: byte 119
                stu     <VIA_port_b             ;  5 t = 1920: row 24
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1932: byte 120
                ldb     ,x+                     ;  6 t = 1936: byte 121
                lda     ,x+                     ;  6 t = 1942: byte 122
                stb     <VIA_shift_reg          ;  4 t = 1948: byte 121
                ldb     ,x+                     ;  6 t = 1952: byte 123
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1964: byte 122
                lda     ,x+                     ;  6 t = 1968: byte 124
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1980: byte 123
                ldb     ,x+                     ;  6 t = 1984: byte 125
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1996: byte 124
                sty     <VIA_port_b             ;  6 t = 2000: row 25
                lda     ,x+                     ;  6 t = 2006: byte 126
                stb     <VIA_shift_reg          ;  4 t = 2012: byte 125
                ldb     ,x+                     ;  6 t = 2016: byte 127
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2028: byte 126
                lda     ,x+                     ;  6 t = 2032: byte 128
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2044: byte 127
                ldb     ,x+                     ;  6 t = 2048: byte 129
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2060: byte 128
                lda     ,x+                     ;  6 t = 2064: byte 130
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2076: byte 129
                stu     <VIA_port_b             ;  5 t = 2080: row 26
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2092: byte 130
                ldb     ,x+                     ;  6 t = 2096: byte 131
                lda     ,x+                     ;  6 t = 2102: byte 132
                stb     <VIA_shift_reg          ;  4 t = 2108: byte 131
                ldb     ,x+                     ;  6 t = 2112: byte 133
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2124: byte 132
                lda     ,x+                     ;  6 t = 2128: byte 134
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2140: byte 133
                ldb     ,x+                     ;  6 t = 2144: byte 135
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2156: byte 134
                sty     <VIA_port_b             ;  6 t = 2160: row 27
                lda     ,x+                     ;  6 t = 2166: byte 136
                stb     <VIA_shift_reg          ;  4 t = 2172: byte 135
                ldb     ,x+                     ;  6 t = 2176: byte 137
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2188: byte 136
                lda     ,x+                     ;  6 t = 2192: byte 138
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2204: byte 137
                ldb     ,x+                     ;  6 t = 2208: byte 139
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2220: byte 138
                lda     ,x+                     ;  6 t = 2224: byte 140
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2236: byte 139
                stu     <VIA_port_b             ;  5 t = 2240: row 28
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2252: byte 140
                ldb     ,x+                     ;  6 t = 2256: byte 141
                lda     ,x+                     ;  6 t = 2262: byte 142
                stb     <VIA_shift_reg          ;  4 t = 2268: byte 141
                ldb     ,x+                     ;  6 t = 2272: byte 143
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2284: byte 142
                lda     ,x+                     ;  6 t = 2288: byte 144
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2300: byte 143
                ldb     ,x+                     ;  6 t = 2304: byte 145
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2316: byte 144
                sty     <VIA_port_b             ;  6 t = 2320: row 29
                lda     ,x+                     ;  6 t = 2326: byte 146
                stb     <VIA_shift_reg          ;  4 t = 2332: byte 145
                ldb     ,x+                     ;  6 t = 2336: byte 147
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2348: byte 146
                lda     ,x+                     ;  6 t = 2352: byte 148
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2364: byte 147
                ldb     ,x+                     ;  6 t = 2368: byte 149
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2380: byte 148
                lda     ,x+                     ;  6 t = 2384: byte 150
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2396: byte 149
                stu     <VIA_port_b             ;  5 t = 2400: row 30
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2412: byte 150
                ldb     ,x+                     ;  6 t = 2416: byte 151
                lda     ,x+                     ;  6 t = 2422: byte 152
                stb     <VIA_shift_reg          ;  4 t = 2428: byte 151
                ldb     ,x+                     ;  6 t = 2432: byte 153
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2444: byte 152
                lda     ,x+                     ;  6 t = 2448: byte 154
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2460: byte 153
                ldb     ,x+                     ;  6 t = 2464: byte 155
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2476: byte 154
                sty     <VIA_port_b             ;  6 t = 2480: row 31
                lda     ,x+                     ;  6 t = 2486: byte 156
                stb     <VIA_shift_reg          ;  4 t = 2492: byte 155
                ldb     ,x+                     ;  6 t = 2496: byte 157
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2508: byte 156
                lda     ,x+                     ;  6 t = 2512: byte 158
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2524: byte 157
                ldb     ,x+                     ;  6 t = 2528: byte 159
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2540: byte 158
                lda     ,x+                     ;  6 t = 2544: byte 160
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2556: byte 159
                stu     <VIA_port_b             ;  5 t = 2560: row 32
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2572: byte 160
                ldb     ,x+                     ;  6 t = 2576: byte 161
                lda     ,x+                     ;  6 t = 2582: byte 162
                stb     <VIA_shift_reg          ;  4 t = 2588: byte 161
                ldb     ,x+                     ;  6 t = 2592: byte 163
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2604: byte 162
                lda     ,x+                     ;  6 t = 2608: byte 164
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2620: byte 163
                ldb     ,x+                     ;  6 t = 2624: byte 165
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2636: byte 164
                sty     <VIA_port_b             ;  6 t = 2640: row 33
                lda     ,x+                     ;  6 t = 2646: byte 166
                stb     <VIA_shift_reg          ;  4 t = 2652: byte 165
                ldb     ,x+                     ;  6 t = 2656: byte 167
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2668: byte 166
                lda     ,x+                     ;  6 t = 2672: byte 168
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2684: byte 167
                ldb     ,x+                     ;  6 t = 2688: byte 169
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2700: byte 168
                lda     ,x+                     ;  6 t = 2704: byte 170
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2716: byte 169
                stu     <VIA_port_b             ;  5 t = 2720: row 34
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2732: byte 170
                ldb     ,x+                     ;  6 t = 2736: byte 171
                lda     ,x+                     ;  6 t = 2742: byte 172
                stb     <VIA_shift_reg          ;  4 t = 2748: byte 171
                ldb     ,x+                     ;  6 t = 2752: byte 173
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2764: byte 172
                lda     ,x+                     ;  6 t = 2768: byte 174
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2780: byte 173
                ldb     ,x+                     ;  6 t = 2784: byte 175
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2796: byte 174
                sty     <VIA_port_b             ;  6 t = 2800: row 35
                lda     ,x+                     ;  6 t = 2806: byte 176
                stb     <VIA_shift_reg          ;  4 t = 2812: byte 175
                ldb     ,x+                     ;  6 t = 2816: byte 177
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2828: byte 176
                lda     ,x+                     ;  6 t = 2832: byte 178
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2844: byte 177
                ldb     ,x+                     ;  6 t = 2848: byte 179
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2860: byte 178
                lda     ,x+                     ;  6 t = 2864: byte 180
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2876: byte 179
                stu     <VIA_port_b             ;  5 t = 2880: row 36
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 2892: byte 180
                ldb     ,x+                     ;  6 t = 2896: byte 181
                lda     ,x+                     ;  6 t = 2902: byte 182
                stb     <VIA_shift_reg          ;  4 t = 2908: byte 181
                ldb     ,x+                     ;  6 t = 2912: byte 183
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2924: byte 182
                lda     ,x+                     ;  6 t = 2928: byte 184
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 2940: byte 183
                ldb     ,x+                     ;  6 t = 2944: byte 185
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2956: byte 184
                sty     <VIA_port_b             ;  6 t = 2960: row 37
                lda     ,x+                     ;  6 t = 2966: byte 186
                stb     <VIA_shift_reg          ;  4 t = 2972: byte 185
                ldb     ,x+                     ;  6 t = 2976: byte 187
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 2988: byte 186
                lda     ,x+                     ;  6 t = 2992: byte 188
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3004: byte 187
                ldb     ,x+                     ;  6 t = 3008: byte 189
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3020: byte 188
                lda     ,x+                     ;  6 t = 3024: byte 190
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3036: byte 189
                stu     <VIA_port_b             ;  5 t = 3040: row 38
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3052: byte 190
                ldb     ,x+                     ;  6 t = 3056: byte 191
                lda     ,x+                     ;  6 t = 3062: byte 192
                stb     <VIA_shift_reg          ;  4 t = 3068: byte 191
                ldb     ,x+                     ;  6 t = 3072: byte 193
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3084: byte 192
                lda     ,x+                     ;  6 t = 3088: byte 194
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3100: byte 193
                ldb     ,x+                     ;  6 t = 3104: byte 195
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3116: byte 194
                sty     <VIA_port_b             ;  6 t = 3120: row 39
                lda     ,x+                     ;  6 t = 3126: byte 196
                stb     <VIA_shift_reg          ;  4 t = 3132: byte 195
                ldb     ,x+                     ;  6 t = 3136: byte 197
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3148: byte 196
                lda     ,x+                     ;  6 t = 3152: byte 198
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3164: byte 197
                ldb     ,x+                     ;  6 t = 3168: byte 199
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3180: byte 198
                lda     ,x+                     ;  6 t = 3184: byte 200
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3196: byte 199
                stu     <VIA_port_b             ;  5 t = 3200: row 40
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3212: byte 200
                ldb     ,x+                     ;  6 t = 3216: byte 201
                lda     ,x+                     ;  6 t = 3222: byte 202
                stb     <VIA_shift_reg          ;  4 t = 3228: byte 201
                ldb     ,x+                     ;  6 t = 3232: byte 203
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3244: byte 202
                lda     ,x+                     ;  6 t = 3248: byte 204
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3260: byte 203
                ldb     ,x+                     ;  6 t = 3264: byte 205
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3276: byte 204
                sty     <VIA_port_b             ;  6 t = 3280: row 41
                lda     ,x+                     ;  6 t = 3286: byte 206
                stb     <VIA_shift_reg          ;  4 t = 3292: byte 205
                ldb     ,x+                     ;  6 t = 3296: byte 207
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3308: byte 206
                lda     ,x+                     ;  6 t = 3312: byte 208
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3324: byte 207
                ldb     ,x+                     ;  6 t = 3328: byte 209
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3340: byte 208
                lda     ,x+                     ;  6 t = 3344: byte 210
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3356: byte 209
                stu     <VIA_port_b             ;  5 t = 3360: row 42
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 3372: byte 210
                ldb     ,x+                     ;  6 t = 3376: byte 211
                lda     ,x+                     ;  6 t = 3382: byte 212
                stb     <VIA_shift_reg          ;  4 t = 3388: byte 211
                ldb     ,x+                     ;  6 t = 3392: byte 213
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3404: byte 212
                lda     ,x+                     ;  6 t = 3408: byte 214
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3420: byte 213
                ldb     ,x+                     ;  6 t = 3424: byte 215
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 3436: byte 214
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 3443: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 3452: byte 215
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 2 passes, drift 4
zp_scrubbly_2
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FC                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -4
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80: row 1
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 3
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 5
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                sty     <VIA_port_b             ;  6 t = 560: row 7
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 9
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                stu     <VIA_port_b             ;  5 t = 800: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                ldb     ,x+                     ;  6 t = 816: byte 51
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                sty     <VIA_port_b             ;  6 t = 880: row 11
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                sty     <VIA_port_b             ;  6 t = 1040: row 13
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                stu     <VIA_port_b             ;  5 t = 1120: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldb     ,x+                     ;  6 t = 1136: byte 71
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldb     ,x+                     ;  6 t = 1152: byte 73
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                lda     ,x+                     ;  6 t = 1168: byte 74
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                sty     <VIA_port_b             ;  6 t = 1200: row 15
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldb     ,x+                     ;  6 t = 1248: byte 79
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                lda     ,x+                     ;  6 t = 1264: byte 80
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                stu     <VIA_port_b             ;  5 t = 1280: row 16
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                ldb     ,x+                     ;  6 t = 1296: byte 81
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                ldb     ,x+                     ;  6 t = 1344: byte 85
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                sty     <VIA_port_b             ;  6 t = 1360: row 17
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                ldb     ,x+                     ;  6 t = 1408: byte 89
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                lda     ,x+                     ;  6 t = 1424: byte 90
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                stu     <VIA_port_b             ;  5 t = 1440: row 18
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                ldb     ,x+                     ;  6 t = 1456: byte 91
                lda     ,x+                     ;  6 t = 1462: byte 92
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                lda     ,x+                     ;  6 t = 1488: byte 94
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                sty     <VIA_port_b             ;  6 t = 1520: row 19
                lda     ,x+                     ;  6 t = 1526: byte 96
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                ldb     ,x+                     ;  6 t = 1536: byte 97
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                lda     ,x+                     ;  6 t = 1552: byte 98
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                lda     ,x+                     ;  6 t = 1584: byte 100
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                stu     <VIA_port_b             ;  5 t = 1600: row 20
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                ldb     ,x+                     ;  6 t = 1616: byte 101
                lda     ,x+                     ;  6 t = 1622: byte 102
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                lda     ,x+                     ;  6 t = 1648: byte 104
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                ldb     ,x+                     ;  6 t = 1664: byte 105
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                sty     <VIA_port_b             ;  6 t = 1680: row 21
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1715: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting left
                ldy     #$8004                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 4
                ldu     #$01B0                  ;  3 (the sample-and-hold settles)
                ldy     #$0150                  ;  4 
                ldd     #$81B0                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed -80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 131: row 2
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 211: row 3
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 291: row 4
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 371: row 5
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 451: row 6
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 531: row 7
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 611: row 8
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 691: row 9
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 771: row 10
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 851: row 11
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                lda     ,x+                     ;  6 t = 864: byte 54
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 931: row 12
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                ldb     ,x+                     ;  6 t = 944: byte 59
                lda     ,x+                     ;  6 t = 950: byte 60
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1011: row 13
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                lda     ,x+                     ;  6 t = 1024: byte 64
                ldb     ,x+                     ;  6 t = 1030: byte 65
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1091: row 14
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldb     ,x+                     ;  6 t = 1152: byte 73
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1171: row 15
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                lda     ,x+                     ;  6 t = 1184: byte 74
                ldb     ,x+                     ;  6 t = 1190: byte 75
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                lda     ,x+                     ;  6 t = 1200: byte 76
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1251: row 16
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                ldb     ,x+                     ;  6 t = 1264: byte 79
                lda     ,x+                     ;  6 t = 1270: byte 80
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                ldb     ,x+                     ;  6 t = 1280: byte 81
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                lda     ,x+                     ;  6 t = 1296: byte 82
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1331: row 17
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                lda     ,x+                     ;  6 t = 1344: byte 84
                ldb     ,x+                     ;  6 t = 1350: byte 85
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                lda     ,x+                     ;  6 t = 1360: byte 86
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                lda     ,x+                     ;  6 t = 1392: byte 88
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1411: row 18
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                ldb     ,x+                     ;  6 t = 1424: byte 89
                lda     ,x+                     ;  6 t = 1430: byte 90
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                ldb     ,x+                     ;  6 t = 1440: byte 91
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                lda     ,x+                     ;  6 t = 1456: byte 92
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1491: row 19
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                lda     ,x+                     ;  6 t = 1504: byte 94
                ldb     ,x+                     ;  6 t = 1510: byte 95
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                ldb     ,x+                     ;  6 t = 1536: byte 97
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                lda     ,x+                     ;  6 t = 1552: byte 98
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1571: row 20
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                ldb     ,x+                     ;  6 t = 1584: byte 99
                lda     ,x+                     ;  6 t = 1590: byte 100
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                ldb     ,x+                     ;  6 t = 1600: byte 101
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                lda     ,x+                     ;  6 t = 1616: byte 102
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                ldb     ,x+                     ;  6 t = 1632: byte 103
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1651: row 21
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                lda     ,x+                     ;  6 t = 1664: byte 104
                ldb     ,x+                     ;  6 t = 1670: byte 105
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                lda     ,x+                     ;  6 t = 1680: byte 106
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1731: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 3 passes, drift 6
zp_scrubbly_3
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FA                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -6
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80: row 1
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 3
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                stu     <VIA_port_b             ;  5 t = 320: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 5
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                sty     <VIA_port_b             ;  6 t = 560: row 7
                lda     ,x+                     ;  6 t = 566: byte 36
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                stu     <VIA_port_b             ;  5 t = 640: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                ldb     ,x+                     ;  6 t = 656: byte 41
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 9
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                stu     <VIA_port_b             ;  5 t = 800: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                ldb     ,x+                     ;  6 t = 816: byte 51
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                sty     <VIA_port_b             ;  6 t = 880: row 11
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                sty     <VIA_port_b             ;  6 t = 1040: row 13
                lda     ,x+                     ;  6 t = 1046: byte 66
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1123: row 14
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldb     ,x+                     ;  6 t = 1136: byte 71
                lda     ,x+                     ;  6 t = 1142: byte 72
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1155: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting right
                ldy     #$8006                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 6
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 51: row 1
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 t = 64: byte 4
                ldb     ,x+                     ;  6 t = 70: byte 5
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 131: row 2
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 211: row 3
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 291: row 4
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 371: row 5
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 451: row 6
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 531: row 7
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                lda     ,x+                     ;  6 t = 544: byte 34
                ldb     ,x+                     ;  6 t = 550: byte 35
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                ldb     ,x+                     ;  6 t = 576: byte 37
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 611: row 8
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 691: row 9
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                lda     ,x+                     ;  6 t = 704: byte 44
                ldb     ,x+                     ;  6 t = 710: byte 45
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 771: row 10
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                lda     ,x+                     ;  6 t = 816: byte 52
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 851: row 11
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                lda     ,x+                     ;  6 t = 864: byte 54
                ldb     ,x+                     ;  6 t = 870: byte 55
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                lda     ,x+                     ;  6 t = 912: byte 58
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 931: row 12
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                ldb     ,x+                     ;  6 t = 944: byte 59
                lda     ,x+                     ;  6 t = 950: byte 60
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                lda     ,x+                     ;  6 t = 976: byte 62
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 1011: row 13
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                lda     ,x+                     ;  6 t = 1024: byte 64
                ldb     ,x+                     ;  6 t = 1030: byte 65
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                ldb     ,x+                     ;  6 t = 1056: byte 67
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                lda     ,x+                     ;  6 t = 1072: byte 68
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 1091: row 14
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                ldb     ,x+                     ;  6 t = 1104: byte 69
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1155: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                clr     <VIA_shift_reg          ;  6 spot off
; pass 2: down, starting right
                ldy     #$80FA                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -6
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                sty     <VIA_port_b             ;  6 t = 176: row 3
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 5
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                stu     <VIA_port_b             ;  5 t = 416: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                sty     <VIA_port_b             ;  6 t = 496: row 7
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                stu     <VIA_port_b             ;  5 t = 576: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                lda     ,x+                     ;  6 t = 624: byte 40
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                sty     <VIA_port_b             ;  6 t = 656: row 9
                lda     ,x+                     ;  6 t = 662: byte 42
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                ldb     ,x+                     ;  6 t = 672: byte 43
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                lda     ,x+                     ;  6 t = 720: byte 46
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                stu     <VIA_port_b             ;  5 t = 736: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                ldb     ,x+                     ;  6 t = 752: byte 47
                lda     ,x+                     ;  6 t = 758: byte 48
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                ldb     ,x+                     ;  6 t = 768: byte 49
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                lda     ,x+                     ;  6 t = 784: byte 50
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                sty     <VIA_port_b             ;  6 t = 816: row 11
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                ldb     ,x+                     ;  6 t = 864: byte 55
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                lda     ,x+                     ;  6 t = 880: byte 56
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                stu     <VIA_port_b             ;  5 t = 896: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                ldb     ,x+                     ;  6 t = 912: byte 57
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                ldb     ,x+                     ;  6 t = 960: byte 61
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                sty     <VIA_port_b             ;  6 t = 976: row 13
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                lda     ,x+                     ;  6 t = 1008: byte 64
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                stu     <VIA_port_b             ;  5 t = 1056: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                lda     ,x+                     ;  6 t = 1104: byte 70
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1139: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 1 passes, drift 3
zp_poglet_1
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FD                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -3
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 9
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 11
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                stu     <VIA_port_b             ;  5 t = 576: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                sty     <VIA_port_b             ;  6 t = 624: row 13
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                stu     <VIA_port_b             ;  5 t = 672: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 15
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                stu     <VIA_port_b             ;  5 t = 768: row 16
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                sty     <VIA_port_b             ;  6 t = 816: row 17
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                stu     <VIA_port_b             ;  5 t = 864: row 18
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                ldb     ,x+                     ;  6 t = 880: byte 55
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                sty     <VIA_port_b             ;  6 t = 912: row 19
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 20
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                sty     <VIA_port_b             ;  6 t = 1008: row 21
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                stu     <VIA_port_b             ;  5 t = 1056: row 22
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 23
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                stu     <VIA_port_b             ;  5 t = 1152: row 24
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                sty     <VIA_port_b             ;  6 t = 1200: row 25
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                stu     <VIA_port_b             ;  5 t = 1248: row 26
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                ldb     ,x+                     ;  6 t = 1264: byte 79
                lda     ,x+                     ;  6 t = 1270: byte 80
                stb     <VIA_shift_reg          ;  4 t = 1276: byte 79
                ldb     ,x+                     ;  6 t = 1280: byte 81
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1292: byte 80
                sty     <VIA_port_b             ;  6 t = 1296: row 27
                lda     ,x+                     ;  6 t = 1302: byte 82
                stb     <VIA_shift_reg          ;  4 t = 1308: byte 81
                ldb     ,x+                     ;  6 t = 1312: byte 83
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1324: byte 82
                lda     ,x+                     ;  6 t = 1328: byte 84
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1340: byte 83
                stu     <VIA_port_b             ;  5 t = 1344: row 28
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1356: byte 84
                ldb     ,x+                     ;  6 t = 1360: byte 85
                lda     ,x+                     ;  6 t = 1366: byte 86
                stb     <VIA_shift_reg          ;  4 t = 1372: byte 85
                ldb     ,x+                     ;  6 t = 1376: byte 87
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1388: byte 86
                sty     <VIA_port_b             ;  6 t = 1392: row 29
                lda     ,x+                     ;  6 t = 1398: byte 88
                stb     <VIA_shift_reg          ;  4 t = 1404: byte 87
                ldb     ,x+                     ;  6 t = 1408: byte 89
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1420: byte 88
                lda     ,x+                     ;  6 t = 1424: byte 90
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1436: byte 89
                stu     <VIA_port_b             ;  5 t = 1440: row 30
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1452: byte 90
                ldb     ,x+                     ;  6 t = 1456: byte 91
                lda     ,x+                     ;  6 t = 1462: byte 92
                stb     <VIA_shift_reg          ;  4 t = 1468: byte 91
                ldb     ,x+                     ;  6 t = 1472: byte 93
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1484: byte 92
                sty     <VIA_port_b             ;  6 t = 1488: row 31
                lda     ,x+                     ;  6 t = 1494: byte 94
                stb     <VIA_shift_reg          ;  4 t = 1500: byte 93
                ldb     ,x+                     ;  6 t = 1504: byte 95
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1516: byte 94
                lda     ,x+                     ;  6 t = 1520: byte 96
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1532: byte 95
                stu     <VIA_port_b             ;  5 t = 1536: row 32
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1548: byte 96
                ldb     ,x+                     ;  6 t = 1552: byte 97
                lda     ,x+                     ;  6 t = 1558: byte 98
                stb     <VIA_shift_reg          ;  4 t = 1564: byte 97
                ldb     ,x+                     ;  6 t = 1568: byte 99
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1580: byte 98
                sty     <VIA_port_b             ;  6 t = 1584: row 33
                lda     ,x+                     ;  6 t = 1590: byte 100
                stb     <VIA_shift_reg          ;  4 t = 1596: byte 99
                ldb     ,x+                     ;  6 t = 1600: byte 101
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1612: byte 100
                lda     ,x+                     ;  6 t = 1616: byte 102
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1628: byte 101
                stu     <VIA_port_b             ;  5 t = 1632: row 34
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1644: byte 102
                ldb     ,x+                     ;  6 t = 1648: byte 103
                lda     ,x+                     ;  6 t = 1654: byte 104
                stb     <VIA_shift_reg          ;  4 t = 1660: byte 103
                ldb     ,x+                     ;  6 t = 1664: byte 105
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1676: byte 104
                sty     <VIA_port_b             ;  6 t = 1680: row 35
                lda     ,x+                     ;  6 t = 1686: byte 106
                stb     <VIA_shift_reg          ;  4 t = 1692: byte 105
                ldb     ,x+                     ;  6 t = 1696: byte 107
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1708: byte 106
                lda     ,x+                     ;  6 t = 1712: byte 108
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1724: byte 107
                stu     <VIA_port_b             ;  5 t = 1728: row 36
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1740: byte 108
                ldb     ,x+                     ;  6 t = 1744: byte 109
                lda     ,x+                     ;  6 t = 1750: byte 110
                stb     <VIA_shift_reg          ;  4 t = 1756: byte 109
                ldb     ,x+                     ;  6 t = 1760: byte 111
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1772: byte 110
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1779: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1788: byte 111
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 2 passes, drift 7
zp_poglet_2
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80F9                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -7
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 9
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 11
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                stu     <VIA_port_b             ;  5 t = 576: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                sty     <VIA_port_b             ;  6 t = 624: row 13
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                stu     <VIA_port_b             ;  5 t = 672: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 15
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 739: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting left
                ldy     #$8007                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 7
                ldu     #$01B0                  ;  3 (the sample-and-hold settles)
                ldy     #$0150                  ;  4 
                ldd     #$81B0                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed -80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 83: row 2
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 131: row 3
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 179: row 4
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 227: row 5
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 275: row 6
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 323: row 7
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 371: row 8
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 419: row 9
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 467: row 10
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 515: row 11
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 563: row 12
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                lda     ,x+                     ;  6 t = 576: byte 36
                ldb     ,x+                     ;  6 t = 582: byte 37
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                lda     ,x+                     ;  6 t = 592: byte 38
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 611: row 13
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                ldb     ,x+                     ;  6 t = 624: byte 39
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 659: row 14
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                lda     ,x+                     ;  6 t = 672: byte 42
                ldb     ,x+                     ;  6 t = 678: byte 43
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                lda     ,x+                     ;  6 t = 688: byte 44
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 707: row 15
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                ldb     ,x+                     ;  6 t = 720: byte 45
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 755: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 3 passes, drift 10
zp_poglet_3
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80F6                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -10
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 9
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 11
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 547: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting left
                ldy     #$800A                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 10
                ldu     #$01B0                  ;  3 (the sample-and-hold settles)
                ldy     #$0150                  ;  4 
                ldd     #$81B0                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed -80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 83: row 2
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 131: row 3
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                ldb     ,x+                     ;  6 t = 144: byte 9
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 179: row 4
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 227: row 5
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                ldb     ,x+                     ;  6 t = 240: byte 15
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 275: row 6
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 323: row 7
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                ldb     ,x+                     ;  6 t = 336: byte 21
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 371: row 8
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 419: row 9
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                ldb     ,x+                     ;  6 t = 432: byte 27
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 467: row 10
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                lda     ,x+                     ;  6 t = 480: byte 30
                ldb     ,x+                     ;  6 t = 486: byte 31
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                lda     ,x+                     ;  6 t = 496: byte 32
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 515: row 11
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                ldb     ,x+                     ;  6 t = 528: byte 33
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 547: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                clr     <VIA_shift_reg          ;  6 spot off
; pass 2: down, starting right
                ldy     #$80F6                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -10
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                stu     <VIA_port_b             ;  5 t = 64: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                sty     <VIA_port_b             ;  6 t = 112: row 3
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                stu     <VIA_port_b             ;  5 t = 160: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                sty     <VIA_port_b             ;  6 t = 208: row 5
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                stu     <VIA_port_b             ;  5 t = 256: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                sty     <VIA_port_b             ;  6 t = 304: row 7
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                stu     <VIA_port_b             ;  5 t = 352: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                sty     <VIA_port_b             ;  6 t = 400: row 9
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                stu     <VIA_port_b             ;  5 t = 448: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                sty     <VIA_port_b             ;  6 t = 496: row 11
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 547: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 1 passes, drift 3
zp_hooter_1
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80FD                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -3
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 9
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldb     ,x+                     ;  6 t = 512: byte 33
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                sty     <VIA_port_b             ;  6 t = 528: row 11
                lda     ,x+                     ;  6 t = 534: byte 34
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldb     ,x+                     ;  6 t = 544: byte 35
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                lda     ,x+                     ;  6 t = 560: byte 36
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 572: byte 35
                stu     <VIA_port_b             ;  5 t = 576: row 12
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 588: byte 36
                ldb     ,x+                     ;  6 t = 592: byte 37
                lda     ,x+                     ;  6 t = 598: byte 38
                stb     <VIA_shift_reg          ;  4 t = 604: byte 37
                ldb     ,x+                     ;  6 t = 608: byte 39
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 620: byte 38
                sty     <VIA_port_b             ;  6 t = 624: row 13
                lda     ,x+                     ;  6 t = 630: byte 40
                stb     <VIA_shift_reg          ;  4 t = 636: byte 39
                ldb     ,x+                     ;  6 t = 640: byte 41
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 652: byte 40
                lda     ,x+                     ;  6 t = 656: byte 42
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 668: byte 41
                stu     <VIA_port_b             ;  5 t = 672: row 14
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 684: byte 42
                ldb     ,x+                     ;  6 t = 688: byte 43
                lda     ,x+                     ;  6 t = 694: byte 44
                stb     <VIA_shift_reg          ;  4 t = 700: byte 43
                ldb     ,x+                     ;  6 t = 704: byte 45
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 716: byte 44
                sty     <VIA_port_b             ;  6 t = 720: row 15
                lda     ,x+                     ;  6 t = 726: byte 46
                stb     <VIA_shift_reg          ;  4 t = 732: byte 45
                ldb     ,x+                     ;  6 t = 736: byte 47
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 748: byte 46
                lda     ,x+                     ;  6 t = 752: byte 48
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 764: byte 47
                stu     <VIA_port_b             ;  5 t = 768: row 16
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 780: byte 48
                ldb     ,x+                     ;  6 t = 784: byte 49
                lda     ,x+                     ;  6 t = 790: byte 50
                stb     <VIA_shift_reg          ;  4 t = 796: byte 49
                ldb     ,x+                     ;  6 t = 800: byte 51
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 812: byte 50
                sty     <VIA_port_b             ;  6 t = 816: row 17
                lda     ,x+                     ;  6 t = 822: byte 52
                stb     <VIA_shift_reg          ;  4 t = 828: byte 51
                ldb     ,x+                     ;  6 t = 832: byte 53
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 844: byte 52
                lda     ,x+                     ;  6 t = 848: byte 54
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 860: byte 53
                stu     <VIA_port_b             ;  5 t = 864: row 18
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 876: byte 54
                ldb     ,x+                     ;  6 t = 880: byte 55
                lda     ,x+                     ;  6 t = 886: byte 56
                stb     <VIA_shift_reg          ;  4 t = 892: byte 55
                ldb     ,x+                     ;  6 t = 896: byte 57
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 908: byte 56
                sty     <VIA_port_b             ;  6 t = 912: row 19
                lda     ,x+                     ;  6 t = 918: byte 58
                stb     <VIA_shift_reg          ;  4 t = 924: byte 57
                ldb     ,x+                     ;  6 t = 928: byte 59
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 940: byte 58
                lda     ,x+                     ;  6 t = 944: byte 60
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 956: byte 59
                stu     <VIA_port_b             ;  5 t = 960: row 20
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 972: byte 60
                ldb     ,x+                     ;  6 t = 976: byte 61
                lda     ,x+                     ;  6 t = 982: byte 62
                stb     <VIA_shift_reg          ;  4 t = 988: byte 61
                ldb     ,x+                     ;  6 t = 992: byte 63
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1004: byte 62
                sty     <VIA_port_b             ;  6 t = 1008: row 21
                lda     ,x+                     ;  6 t = 1014: byte 64
                stb     <VIA_shift_reg          ;  4 t = 1020: byte 63
                ldb     ,x+                     ;  6 t = 1024: byte 65
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1036: byte 64
                lda     ,x+                     ;  6 t = 1040: byte 66
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1052: byte 65
                stu     <VIA_port_b             ;  5 t = 1056: row 22
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1068: byte 66
                ldb     ,x+                     ;  6 t = 1072: byte 67
                lda     ,x+                     ;  6 t = 1078: byte 68
                stb     <VIA_shift_reg          ;  4 t = 1084: byte 67
                ldb     ,x+                     ;  6 t = 1088: byte 69
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1100: byte 68
                sty     <VIA_port_b             ;  6 t = 1104: row 23
                lda     ,x+                     ;  6 t = 1110: byte 70
                stb     <VIA_shift_reg          ;  4 t = 1116: byte 69
                ldb     ,x+                     ;  6 t = 1120: byte 71
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1132: byte 70
                lda     ,x+                     ;  6 t = 1136: byte 72
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1148: byte 71
                stu     <VIA_port_b             ;  5 t = 1152: row 24
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 1164: byte 72
                ldb     ,x+                     ;  6 t = 1168: byte 73
                lda     ,x+                     ;  6 t = 1174: byte 74
                stb     <VIA_shift_reg          ;  4 t = 1180: byte 73
                ldb     ,x+                     ;  6 t = 1184: byte 75
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1196: byte 74
                sty     <VIA_port_b             ;  6 t = 1200: row 25
                lda     ,x+                     ;  6 t = 1206: byte 76
                stb     <VIA_shift_reg          ;  4 t = 1212: byte 75
                ldb     ,x+                     ;  6 t = 1216: byte 77
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1228: byte 76
                lda     ,x+                     ;  6 t = 1232: byte 78
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 1244: byte 77
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 1251: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 1260: byte 78
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 2 passes, drift 7
zp_hooter_2
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80F9                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -7
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                lda     ,x+                     ;  6 t = 368: byte 24
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                stu     <VIA_port_b             ;  5 t = 384: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                ldb     ,x+                     ;  6 t = 400: byte 25
                lda     ,x+                     ;  6 t = 406: byte 26
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldb     ,x+                     ;  6 t = 416: byte 27
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                sty     <VIA_port_b             ;  6 t = 432: row 9
                lda     ,x+                     ;  6 t = 438: byte 28
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                ldb     ,x+                     ;  6 t = 448: byte 29
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                lda     ,x+                     ;  6 t = 464: byte 30
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                stu     <VIA_port_b             ;  5 t = 480: row 10
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                ldb     ,x+                     ;  6 t = 496: byte 31
                lda     ,x+                     ;  6 t = 502: byte 32
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 515: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting right
                ldy     #$8007                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 7
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 67: row 2
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 115: row 3
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 163: row 4
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 211: row 5
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 259: row 6
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 307: row 7
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                lda     ,x+                     ;  6 t = 320: byte 20
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 355: row 8
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldb     ,x+                     ;  6 t = 384: byte 25
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 403: row 9
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                lda     ,x+                     ;  6 t = 416: byte 26
                ldb     ,x+                     ;  6 t = 422: byte 27
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                lda     ,x+                     ;  6 t = 432: byte 28
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 444: byte 27
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 451: row 10
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 460: byte 28
                ldb     ,x+                     ;  6 t = 464: byte 29
                lda     ,x+                     ;  6 t = 470: byte 30
                stb     <VIA_shift_reg          ;  4 t = 476: byte 29
                ldb     ,x+                     ;  6 t = 480: byte 31
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 492: byte 30
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 499: row 11
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 508: byte 31
                lda     ,x+                     ;  6 t = 512: byte 32
                ldb     ,x+                     ;  6 t = 518: byte 33
                sta     <VIA_shift_reg          ;  4 t = 524: byte 32
                lda     ,x+                     ;  6 t = 528: byte 34
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 540: byte 33
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 547: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 556: byte 34
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; a multi-pass zigzag: 3 passes, drift 10
zp_hooter_3
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR
; pass 0: down, starting right
                ldy     #$80F6                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -10
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                sty     <VIA_port_b             ;  6 t = 48: row 1
                lda     ,x+                     ;  6 t = 54: byte 4
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 t = 80: byte 6
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                stu     <VIA_port_b             ;  5 t = 96: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                ldb     ,x+                     ;  6 t = 112: byte 7
                lda     ,x+                     ;  6 t = 118: byte 8
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                ldb     ,x+                     ;  6 t = 128: byte 9
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                sty     <VIA_port_b             ;  6 t = 144: row 3
                lda     ,x+                     ;  6 t = 150: byte 10
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                lda     ,x+                     ;  6 t = 176: byte 12
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                stu     <VIA_port_b             ;  5 t = 192: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                ldb     ,x+                     ;  6 t = 208: byte 13
                lda     ,x+                     ;  6 t = 214: byte 14
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                ldb     ,x+                     ;  6 t = 224: byte 15
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                sty     <VIA_port_b             ;  6 t = 240: row 5
                lda     ,x+                     ;  6 t = 246: byte 16
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                lda     ,x+                     ;  6 t = 272: byte 18
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                stu     <VIA_port_b             ;  5 t = 288: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                ldb     ,x+                     ;  6 t = 304: byte 19
                lda     ,x+                     ;  6 t = 310: byte 20
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                ldb     ,x+                     ;  6 t = 320: byte 21
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                sty     <VIA_port_b             ;  6 t = 336: row 7
                lda     ,x+                     ;  6 t = 342: byte 22
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 371: ramp off
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                clr     <VIA_shift_reg          ;  6 spot off
; pass 1: up, starting left
                ldy     #$800A                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed 10
                ldu     #$01B0                  ;  3 (the sample-and-hold settles)
                ldy     #$0150                  ;  4 
                ldd     #$81B0                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed -80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                sty     <VIA_port_b             ;  6 t = 16: row 1
                lda     ,x+                     ;  6 t = 22: byte 2
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                ldb     ,x+                     ;  6 t = 32: byte 3
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 67: row 2
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                ldb     ,x+                     ;  6 t = 80: byte 5
                lda     ,x+                     ;  6 t = 86: byte 6
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                ldb     ,x+                     ;  6 t = 96: byte 7
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 115: row 3
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                lda     ,x+                     ;  6 t = 128: byte 8
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 163: row 4
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                ldb     ,x+                     ;  6 t = 176: byte 11
                lda     ,x+                     ;  6 t = 182: byte 12
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                ldb     ,x+                     ;  6 t = 192: byte 13
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 211: row 5
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                lda     ,x+                     ;  6 t = 224: byte 14
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 259: row 6
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                ldb     ,x+                     ;  6 t = 272: byte 17
                lda     ,x+                     ;  6 t = 278: byte 18
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                ldb     ,x+                     ;  6 t = 288: byte 19
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                brn     *                       ;  3 
                sty     <VIA_port_b             ;  6 t = 307: row 7
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                lda     ,x+                     ;  6 t = 320: byte 20
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                brn     *                       ;  3 
                stu     <VIA_port_b             ;  5 t = 355: row 8
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                ldb     ,x+                     ;  6 t = 368: byte 23
                lda     ,x+                     ;  6 t = 374: byte 24
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 387: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                clr     <VIA_shift_reg          ;  6 spot off
; pass 2: down, starting right
                ldy     #$80F6                  ;  4 
                sty     <VIA_port_b             ;  6 ramp off, mux on: Y speed -10
                ldu     #$0150                  ;  3 (the sample-and-hold settles)
                ldy     #$01B0                  ;  4 
                ldd     #$8150                  ;  3 
                std     <VIA_port_b             ;  5 mux off, X speed 80
                lda     ,x+                     ;  6 
                ldb     ,x+                     ;  6 
                stu     <VIA_port_b             ;  5 t = 0: ramp on
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 t = 16: byte 2
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 28: byte 1
                sty     <VIA_port_b             ;  6 t = 32: row 1
                ldb     ,x+                     ;  6 t = 38: byte 3
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 t = 48: byte 4
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 60: byte 3
                ldb     ,x+                     ;  6 t = 64: byte 5
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                stu     <VIA_port_b             ;  5 t = 80: row 2
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 92: byte 5
                lda     ,x+                     ;  6 t = 96: byte 6
                ldb     ,x+                     ;  6 t = 102: byte 7
                sta     <VIA_shift_reg          ;  4 t = 108: byte 6
                lda     ,x+                     ;  6 t = 112: byte 8
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 124: byte 7
                sty     <VIA_port_b             ;  6 t = 128: row 3
                ldb     ,x+                     ;  6 t = 134: byte 9
                sta     <VIA_shift_reg          ;  4 t = 140: byte 8
                lda     ,x+                     ;  6 t = 144: byte 10
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 156: byte 9
                ldb     ,x+                     ;  6 t = 160: byte 11
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 172: byte 10
                stu     <VIA_port_b             ;  5 t = 176: row 4
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 188: byte 11
                lda     ,x+                     ;  6 t = 192: byte 12
                ldb     ,x+                     ;  6 t = 198: byte 13
                sta     <VIA_shift_reg          ;  4 t = 204: byte 12
                lda     ,x+                     ;  6 t = 208: byte 14
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 220: byte 13
                sty     <VIA_port_b             ;  6 t = 224: row 5
                ldb     ,x+                     ;  6 t = 230: byte 15
                sta     <VIA_shift_reg          ;  4 t = 236: byte 14
                lda     ,x+                     ;  6 t = 240: byte 16
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 252: byte 15
                ldb     ,x+                     ;  6 t = 256: byte 17
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 268: byte 16
                stu     <VIA_port_b             ;  5 t = 272: row 6
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 284: byte 17
                lda     ,x+                     ;  6 t = 288: byte 18
                ldb     ,x+                     ;  6 t = 294: byte 19
                sta     <VIA_shift_reg          ;  4 t = 300: byte 18
                lda     ,x+                     ;  6 t = 304: byte 20
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 316: byte 19
                sty     <VIA_port_b             ;  6 t = 320: row 7
                ldb     ,x+                     ;  6 t = 326: byte 21
                sta     <VIA_shift_reg          ;  4 t = 332: byte 20
                lda     ,x+                     ;  6 t = 336: byte 22
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 348: byte 21
                ldb     ,x+                     ;  6 t = 352: byte 23
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 364: byte 22
                stu     <VIA_port_b             ;  5 t = 368: row 8
                nop                             ;  2 
                nop                             ;  2 
                brn     *                       ;  3 
                stb     <VIA_shift_reg          ;  4 t = 380: byte 23
                lda     ,x+                     ;  6 t = 384: byte 24
                ldb     ,x+                     ;  6 t = 390: byte 25
                sta     <VIA_shift_reg          ;  4 t = 396: byte 24
                lda     ,x+                     ;  6 t = 400: byte 26
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                stb     <VIA_shift_reg          ;  4 t = 412: byte 25
                ldu     #$8100                  ;  3 
                stu     <VIA_port_b             ;  5 t = 419: ramp off
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 428: byte 26
                clr     <VIA_shift_reg          ;  6 spot off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back
                rts                             ;  5 

; columns of 4 bytes (32 pixels): 99 cycles a column (102 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col4_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col4_down_c             ;  5 (not timed)
col4_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col4_up_c               ;  5 (not timed)
col4_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col4_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col4_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col4_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                sty     <VIA_port_b             ;  6 t = 64 = e: ramp off, mux on, DAC = the next Y speed
col4_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col4_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                sty     <VIA_port_b             ;  6 t = 64 = e: ramp off, mux on, DAC = the next Y speed
                bra     col4_d_loop             ;  3 (in the settling time)
col4_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col4_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col4_u_loop             ;  3 
col4_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 5 bytes (40 pixels): 115 cycles a column (118 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col5_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col5_down_c             ;  5 (not timed)
col5_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col5_up_c               ;  5 (not timed)
col5_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col5_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col5_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col5_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80 = e: ramp off, mux on, DAC = the next Y speed
col5_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col5_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                sty     <VIA_port_b             ;  6 t = 80 = e: ramp off, mux on, DAC = the next Y speed
                bra     col5_d_loop             ;  3 (in the settling time)
col5_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col5_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col5_u_loop             ;  3 
col5_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

; columns of 6 bytes (48 pixels): 131 cycles a column (134 after an up column)
; in: X = the first column's data, $C880 = the number of columns + 1, the beam at the
; first column's start (half a pixel left of it, at the top for _down, the bottom for _up)
; facing left: the same columns, drawn from the right, the slide going left
col6_down_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col6_down_c             ;  5 (not timed)
col6_up_l
                ldu     #$81D8                  ;  3 port B = mux off, DAC = -40: the slide across
                lbra    col6_up_c               ;  5 (not timed)
col6_down
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col6_down_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$80B0                  ;  4 Y speed down
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
col6_d_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col6_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$8050                  ;  4 the Y speed after this column (up)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96 = e: ramp off, mux on, DAC = the next Y speed
col6_u_loop
                dec     $C880                   ;  7 the sample-and-hold settles from here...
                lbeq    col6_out                ;  5 (5 not branching)
                lda     ,x+                     ;  6 the first byte
                ldb     #$01                    ;  2 port B = ramp on
                ldy     #$80B0                  ;  4 the Y speed after this column (down)
                stu     <VIA_port_b             ;  5 e+30: ...to here: mux off, DAC = the slide
                stb     <VIA_port_b             ;  4 t = 0: ramp on
                clr     <VIA_port_a             ;  6 t = 4: X speed 0 (the slide: a pixel across)
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 12: byte 0
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 28: byte 1
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 44: byte 2
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 60: byte 3
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 76: byte 4
                lda     ,x+                     ;  6 
                nop                             ;  2 
                nop                             ;  2 
                nop                             ;  2 
                sta     <VIA_shift_reg          ;  4 t = 92: byte 5
                sty     <VIA_port_b             ;  6 t = 96 = e: ramp off, mux on, DAC = the next Y speed
                bra     col6_d_loop             ;  3 (in the settling time)
col6_up
                ldu     #$8128                  ;  3 port B = mux off, DAC = 40: the slide across
col6_up_c
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 ramp off, mux off, before port B takes over the ramp
                lda     #$18                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR: ramp from port B, shift register out on the clock
                ldy     #$8050                  ;  4 Y speed up
                sty     <VIA_port_b             ;  6 mux on, DAC = the first Y speed
                bra     col6_u_loop             ;  3 
col6_out
                lda     #$81                    ;  2 
                sta     <VIA_port_b             ;  4 mux off
                lda     #$98                    ;  2 
                sta     <VIA_aux_cntl           ;  4 ACR back: the ramp from timer 1 (run out: off)
                rts                             ;  5 

