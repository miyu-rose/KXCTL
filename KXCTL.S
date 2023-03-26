;========================================================================================
;
; KXCTL version 1.01 by はう (Hau) ＆ みゆ (miyu rose)
;
;        KXCTL Designer    みゆ (miyu rose)
;              Programmer  X68KBBS：X68K0001
;                          Twitter：@arith_rose
;
;        Special Adviser   はう (Hau) さま
;        KXCTL Tester      X68KBBS：X68K0024
;                          Twitter：@Hau_oli
;
;       KeplerX Developer  くにちこ (Kunihiko Ohnaka) さま
;                          X68KBBS：X68K0044
;                          Twitter：@kunichiko
;
;========================================================================================

    .include    doscall.mac

    .cpu    68000

;=========================================================================================

    .text
    .even

;=========================================================================================

main:
    lea.l   mysp,sp                             ; スタック領域を自前で確保

;-----------------------------------------------------------------------------------------

SUPERVISORMODE:
    clr.l   -(sp)                               ; SUPERVISOR モード
    DOS     _SUPER
    tst.l   d0                                  ; 元の SSP アドレスが
    bpl     @f                                  ; 正しく取得できたら成功なので次へ
    DOS     _EXIT
@@:
    move.l  d0, (sp)                            ; SUPERVISOR モードになれたので SSP 保存

;-----------------------------------------------------------------------------------------
  
.ifdef __DEBUG__
    bsr     KX_setup_sandbox                    ; テスト環境セットアップ
.endif

    bsr     KX_detect_KeplerX                   ; KeplerX ちゃんを検出
    tst.l   d0                                  ; 検出できてるかな？
    beq     99f                                 ; 検出できてたら次へ

    bsr     disp_NotDetected                    ; 検出できませんでした表示へ

    bra     USERMODE                            ; おしまい
99:

;-----------------------------------------------------------------------------------------

    addq.l  #1,a2                               ; 引数のサイズは無視
arg_check:
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    cmpi.b  #' ',d0                             ; ' ' と比較して
    beq     arg_check                           ;  同じならスキップ
    cmpi.b  #'-',d0                             ; '-' と比較して
    beq     arg_option                          ;  同じならオプション引数チェックへ
    tst.b   d0                                  ; 終端文字と比較して
    beq     99f                                 ;  同じなら引数チェック終了

arg_help:
    bsr     disp_Help                           ; ヘルプ表示
    bra     USERMODE                            ; おしまい


arg_fetchQuad:
    move.b  (a2)+,d0                            ; 引数文字(1文字目)をフェッチ
    lsl.l   #8,d0                               ; 1文字分左へ詰める
    move.b  (a2)+,d0                            ; 引数文字(2文字目)をフェッチ
    lsl.l   #8,d0                               ; 1文字分左へ詰める
    move.b  (a2)+,d0                            ; 引数文字(3文字目)をフェッチ
    lsl.l   #8,d0                               ; 1文字分左へ詰める
    move.b  (a2)+,d0                            ; 引数文字(4文字目)をフェッチ
    or.l    #$20202020,d0                       ; 小文字化($00は' 'になります)
    rts

arg_option:
    bsr     arg_fetchQuad                       ; 4文字分フェッチ(小文字化済)
1:
    cmp.l   #'memd',d0                          ; 'memd' と比較して
    bne     2f                                  ;  違ったら次へ
    move.b  #4,d7                               ; メモリ自動検出機能のbit番号指定
    bra     arg_Peripheral                      ; 有効無効の引数チェックへ
2:
    cmp.l   #'muni',d0                          ; 'muni' と比較して
    bne     3f                                  ;  違ったら次へ
    move.b  #2,d7                               ; メモリ自動検出機能のbit番号指定
    bra     arg_Peripheral                      ; 有効無効の引数チェックへ
3:
    cmp.l   #'midi',d0                          ; 'midi' と比較して
    bne     4f                                  ;  違ったら次へ
    move.b  #1,d7                               ; メモリ自動検出機能のbit番号指定
    bra     arg_Peripheral                      ; 有効無効の引数チェックへ
4:
    cmp.l   #'memb',d0                          ; 'memb' と比較して
    bne     5f                                  ;  違ったら次へ
    move.b  #0,d7                               ; メモリ自動検出機能のbit番号指定
    bra     arg_Peripheral                      ; 有効無効の引数チェックへ
5:
    move.b  #7,d7                               ; S/PDIF(光)入力の音量のbit番号を指定
    cmp.l   #'spdf',d0                          ; 'spdf' と比較して
    bne     6f                                  ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    bsr     arg_help                            ; ヘルプ表示へ
6:
    move.b  #6,d7                               ; mt32pi の音量のbit番号を指定
    cmp.l   #'mt32',d0                          ; 'mt32' と比較して
    bne     7f                                  ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #':',d1                             ; ':' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_mt32piControl                   ; mt32-pi Control の引数チェックへ
@@:
    bra     arg_help                            ; ヘルプ表示へ
7:
    move.b  #5,d7                               ; YM2151 音量のbit番号を指定
    cmp.l   #'x6fm',d0                          ; 'x6fm' と比較して
    bne     8f                                  ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    bra     arg_help                            ; ヘルプ表示へ
8:
    move.b  #4,d7                               ; ADPCM 音量のbit番号を指定
    cmp.l   #'x6ad',d0                          ; 'x6ad' と比較して
    bne     9f                                  ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    bra     arg_help                            ; ヘルプ表示へ
9:
    move.b  #2,d7                               ; Mercury Unit FM 音量のbit番号を指定
    cmp.l   #'mufm',d0                          ; 'mfum' と比較して
    bne     10f                                 ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    bra     arg_help                            ; ヘルプ表示へ
10:
    move.b  #1,d7                               ; Mercury Unit SSG 音量のbit番号を指定
    cmp.l   #'mssg',d0                          ; 'mssg' と比較して
    bne     11f                                 ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    bra     arg_help                            ; ヘルプ表示へ
11:
    move.b  #0,d7                               ; Mercury Unit PCM 音量のbit番号を指定
    cmp.l   #'mpcm',d0                          ; 'mpcm' と比較して
    bne     12f                                 ;  違ったら次へ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #'=',d1                             ; '=' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_set_Volume                      ; 音量の引数チェックへ
@@:
    cmpi.b  #'+',d1                             ; '+' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    cmpi.b  #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    addq.l  #1,a2                               ; 先読み分１文字進める
    bra     arg_turn_Volume                     ; 相対音量の引数チェックへ
@@:
    bra     arg_help                            ; ヘルプ表示へ
12:
    cmp.l   #'mtin',d0                          ; 'mtin' と比較して
    bne     13f                                 ;  違ったら次へ
    move.b  #1,d7                               ; mt32-pi 入力のbit番号指定
    bra     arg_MIDIRouting                     ; MIDI Routing の引数チェックへ
13:
    cmp.l   #'mxot',d0                          ; 'mxot' と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  #0,d7                               ; MIDI 外部出力のbit番号指定
    bra     arg_MIDIRouting                     ; MIDI Routing の引数チェックへ
@@:
    subq.l  #3,a2                               ; 3文字分戻す
    rol.l   #8,d0                               ; 最上位バイトを最下位バイトへ移動

    cmpi.b  #'q',d0                             ; 'q' と比較して
    bne     @f                                  ;  違ったら次へ
    ori.b   #%10000000,flag_kxctl               ; quiet モードのフラグをセット

    bra     arg_check                           ; 次の引数文字チェックへ
@@:
    bra     arg_help                            ; 該当しないのでヘルプ表示へ


arg_Peripheral:
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    cmp.b   #'=',d0                             ; '=' と比較して
    beq     @@f                                 ;  同じなら次へ

    cmp.b   #'+',d0                             ; '+' と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ

    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #' ',d1                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d1                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d1                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
@@:
    bsr     que_PeripheralToggle                ; 指定機能のトグル予約
    bra     arg_check                           ; 次の引数文字チェックへ

@@:
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #' ',d1                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d1                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d1                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
@@:
    cmp.b   #'1',d0                             ; '1' と比較して
    bne     @f                                  ;  違ったら次へ
    bsr     que_PeripheralEnable                ; 指定機能の有効化予約
    bra     arg_check                           ; 次の引数文字チェックへ
@@:
    cmp.b   #'0',d0                             ; '0' と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
    bsr     que_PeripheralDisable               ; 指定機能の無効化予約

    bra     arg_check                           ; 次の引数文字チェックへ


arg_set_Volume:
    move.b  (a2)+,d0                            ; 引数文字をフェッチ

    cmpi.b  #'+',d0                             ; '+' と比較して
    bne     @@f                                 ;  違ってたら次へ
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #' ',d1                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d1                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d1                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
@@:
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示
    cmp.b   #7,d0                               ; 7 と比較して
    bhi     arg_help                            ;  unsigned で超過してたらヘルプ表示

    move.b  d0,d6                               ; 音量指定
    clr.b   d1                                  ; 相対指定フラグをクリア
    bsr     que_Volume                          ; 指定音源の音量予約

    bra     arg_check                           ; 次の引数チェックへ
@@:
    cmpi.b  #'-',d0                             ; '-' と比較して
    bne     @@f                                 ;  違ってたら次へ
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #' ',d1                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d1                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d1                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
@@:
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示
    cmp.b   #8,d0                               ; 8 と比較して
    bhi     arg_help                            ;  unsigned で超過してたらヘルプ表示

    eor.b   #$0F,d0                             ; 下位 4 bit を反転させて
    addq.b  #1,d0                               ;   2 の補数をとることで符号反転
    andi.b  #$0F,d0                             ; 有効 bit である下位 4 bitを マスク
    move.b  d0,d6                               ; 音量指定
    clr.b   d1                                  ; 相対指定フラグをクリア
    bsr     que_Volume                          ; 指定音源の音量予約

    bra     arg_check                           ; 次の引数チェックへ
@@:
    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #' ',d1                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d1                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d1                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
@@:
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示
    bchg.l  #3,d0                               ; 標準音量相対値に変換
    move.b  d0,d6                               ; 音量指定
    clr.b   d1                                  ; 相対指定フラグをクリア
    bsr     que_Volume                          ; 指定音源の音量予約

    bra     arg_check                           ; 次の引数チェックへ


arg_turn_Volume:
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    move.b  (a2),d2                             ; 引数文字を先読み
    cmpi.b  #' ',d2                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d2                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d2                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ
@@:
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示
    cmp     #'-',d1                             ; '-' と比較して
    bne     @f                                  ;  違ったら次へ
    eor.b   #$ff,d0                             ; bit 反転させて
    addq.b  #1,d0                               ;  2 の補数をとることで符号反転
@@:
    move.b  d0,d6                               ; 音量指定
    bsr     que_Volume                          ; 指定音源の音量予約

    bra     arg_check                           ; 次の引数チェックへ


arg_mt32piControl:

    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示へ
    move.b  d0,d1                               ; 書き込む情報バッファへ
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示へ
    lsl.b   #4,d1                               ; 4bit左へ詰める
    or.b    d0,d1                               ; 書き込む情報バッファへ
    move.b  d1,flag_que_mt32piCommand           ; mt32piコマンド予約

    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示へ
    move.b  d0,d1                               ; 書き込む情報バッファへ
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    bsr     mlib_getval                         ; 数値変換
    bmi     arg_help                            ; 変換エラーならヘルプ表示へ
    lsl.b   #4,d1                               ; 4bit左へ詰める
    or.l    d0,d1                               ; 書き込む情報バッファへ
    move.b  d1,flag_que_mt32piParam             ; mt32piコマンド予約

    move.b  (a2),d1                             ; 引数文字を先読み
    cmpi.b  #' ',d1                             ; ' ' と比較して
    beq     @f                                  ;  同じなら次へ
    cmpi.b  #'-',d1                             ; '-' と比較して
    beq     @f                                  ;  同じなら次へ
    tst.b   d1                                  ; 終端文字と比較して
    bne     arg_help                            ;  違ったらヘルプ表示へ

    bset.b  #0,flag_que_mt32piControl           ; mt32-piコントロール予約

    bra     arg_check                           ; 次の引数文字チェックへ


arg_MIDIRouting:
    move.b  (a2)+,d0                            ; 引数文字をフェッチ
    cmp.b   #'=',d0                             ; '=' と比較して
    bne     arg_help                            ; 違ったらヘルプ表示へ

@@:
    bsr     arg_fetchQuad                       ; 4文字分フェッチ(小文字化済)

    cmp.l   #'none',d0                          ; 'none' と比較して
    beq     arg_MIDIRoutingNone                 ; 同じなら接続なしへ
    cmp.l   #'miot',d0                          ; 'miot' と比較して
    beq     arg_MIDIRoutingMIDIIFOut            ; 同じなら MIDI I/F 出力へ
    cmp.l   #'mxin',d0                          ; 'mxin' と比較して
    beq     arg_MIDIRoutingMIDIExtIn            ; 同じなら MIDI 外部入力へ

    subq.l  #3,a2                               ; 3文字分戻す
    rol.l   #8,d0                               ; 最上位バイトを最下位バイトへ移動

    cmpi.b  #'0',d0                             ; '0' と比較して
    beq     arg_MIDIRoutingNone                 ; 同じなら接続なしへ
    cmpi.b  #'1',d0                             ; '0' と比較して
    beq     arg_MIDIRoutingMIDIIFOut            ; 同じなら MIDI I/F 出力へ
    cmpi.b  #'2',d0                             ; '0' と比較して
    beq     arg_MIDIRoutingMIDIExtIn            ; 同じなら MIDI 外部入力へ

    bra     arg_help                            ; 違ったらヘルプへ

arg_MIDIRoutingNone:
    move.b  #$00,d6                             ; 接続なしのソースIDを指定
    bsr     que_MIDIRouting                     ; 指定 MIDI Routing を指定ソースIDで予約
    bra     arg_check                           ; 次の引数文字チェックへ
arg_MIDIRoutingMIDIIFOut:
    move.b  #$01,d6                             ; MIDI I/F 出力のソースIDを指定
    bsr     que_MIDIRouting                     ; 指定 MIDI Routing を指定ソースIDで予約
    bra     arg_check                           ; 次の引数文字チェックへ
arg_MIDIRoutingMIDIExtIn:
    move.b  #$02,d6                             ; MIDI 外部入力のソースIDを指定
    bsr     que_MIDIRouting                     ; 指定 MIDI Routing を指定ソースIDで予約
    bra     arg_check                           ; 次の引数文字チェックへ

99:

;-----------------------------------------------------------------------------------------

    bsr     disp_Title                          ; Title表示
    bsr     disp_border                         ; ボーダー表示
    bsr     disp_Version                        ; バージョン表示
    bsr     disp_delimiter                      ; 区切り線表示
    bsr     exec_que                            ; 予約済queを実行

    btst.b  #6,flag_kxctl                       ; exec済みフラグが
    beq     @f                                  ;  オフなら次へ
    bra     99f
@@:
    bsr     disp_all                            ; 全ステータス表示
99:
    bsr     disp_border                         ; ボーダー表示
    bsr     disp_crlf                           ; 改行表示

;-----------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------

USERMODE:
    DOS     _SUPER                              ; USER モード
    addq.l  #4,sp

;-----------------------------------------------------------------------------------------

EXIT:
    DOS        _EXIT                            ; おしまい

;=========================================================================================

que_PeripheralEnable:                           ; d7 で指定された機能の
    bsr     que_PeripheralCancel                ;  予約キャンセル
    bset.b  d7,flag_que_PeripheralEnable        ;  有効化予約
    rts
que_PeripheralDisable:                          ; d7 で指定された機能の
    bsr     que_PeripheralCancel                ;  予約キャンセル
    bset.b  d7,flag_que_PeripheralDisable       ;  無効化予約
    rts
que_PeripheralToggle:                           ; d7 で指定された機能の
    bsr     que_PeripheralCancel                ;  予約キャンセル
    bchg.b  d7,flag_que_PeripheralToggle        ;  トグル予約
    rts
que_PeripheralCancel:                           ; d7 で指定された機能の
    bclr.b  d7,flag_que_PeripheralEnable        ;  有効化予約キャンセル
    bclr.b  d7,flag_que_PeripheralDisable       ;  無効化予約キャンセル
    bclr.b  d7,flag_que_PeripheralToggle        ;  トグル予約キャンセル
    rts


que_Volume: 
    cmp.b   #7,d7                               ; d7 と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  d6,flag_que_SPDIFVolume             ; S/PDIF(光)入力の音量を予約
    bra     98f
@@:
    cmp.b   #6,d7                               ; d7 と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  d6,flag_que_mt32piVolume            ; mt32piの音量を予約
    bra     98f
@@:
    cmp.b   #5,d7                               ; d7 と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  d6,flag_que_YM2151Volume            ; YM2151 の音量を予約
    bra     98f
@@:
    cmp.b   #4,d7                               ; d7 と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  d6,flag_que_ADPCMVolume             ; ADPCM の音量を予約
    bra     98f
@@:
    cmp.b   #2,d7                               ; d7 と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  d6,flag_que_MercuryUnitFMVolume     ; Mercury Unit FM の音量を予約
    bra     98f
@@:
    cmp.b   #1,d7                               ; d7 と比較して
    bne     @f                                  ;  違ったら次へ
    move.b  d6,flag_que_MercuryUnitSSGVolume    ; Mercury Unit SSG の音量を予約
    bra     98f
@@:
    cmp.b   #0,d7                               ; d7 と比較して
    bne     99f                                 ;  違ったらおしまい
    move.b  d6,flag_que_MercuryUnitPCMVolume    ; Mercury Unit PCMの音量を予約
98:
    tst.b   d1                                  ; 相対音量指定
    bne     @f                                  ;  ならば次へ
    bclr.b  d7,flag_que_turn_Volume             ; 相対音量予約キャンセル
    bset.b  d7,flag_que_set_Volume              ; 音量予約
    bra     99f
@@:
    bclr.b  d7,flag_que_set_Volume              ; 音量予約キャンセル
    bset.b  d7,flag_que_turn_Volume             ;  相対音量予約
99:
    rts


que_MIDIRouting:                                ; d7 で指定された MIDI Routing の
    cmp.b   #1,d7                               ;  bit番号を 1 と比較して
    bne     @f                                  ;   違ったら次へ
    or.b    d6,flag_que_mt32piInputSource       ;  指定ソースIDを mt32-pi 入力ソースとして予約
    bra     98f                                 ;  変更予約へ
@@:
    cmp.b   #0,d7                               ;  bit番号を 0 と比較して
    bne     99f                                 ;   違ったら次へ
    or.b    d6,flag_que_MIDIExtOutSource        ;  指定ソースIDを MIDI外部出力ソースとして予約
98:
    bchg.b  d7,flag_que_MIDIRouting             ;  MIDI Routing 変更予約
99:
    rts


exec_que:
exec_que_PeripheralToggle:                      ; Mercury Unit 機能の
    btst.b  #2,flag_que_PeripheralToggle        ;  有効無効トグル予約が
    beq     @f                                  ;   されてなければ次へ
    bsr     KX_toggle_MercuryUnit               ;  機能の有効無効をトグル
    bsr     disp_MercuryUnit                    ;  機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; MIDI I/F Board 機能の
    btst.b  #1,flag_que_PeripheralToggle        ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_toggle_MIDIIFBoard               ;   機能の有効無効をトグル
    bsr     disp_MIDIIFBoard                    ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; Memory Board 機能の
    btst.b  #0,flag_que_PeripheralToggle        ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_toggle_MemoryBoard               ;   機能の有効無効をトグル
    bsr     disp_MemoryBoard                    ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; 自動メモリ検出機能の
    btst.b  #4,flag_que_PeripheralToggle        ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_toggle_AutoMemoryDetection       ;   機能の有効無効をトグル
    bsr     disp_AutoMemoryDetection            ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:

exec_que_PeripheralDisable:                     ; Mercury Unit 機能の
    btst.b  #2,flag_que_PeripheralDisable       ;  有効無効トグル予約が
    beq     @f                                  ;   されてなければ次へ
    bsr     KX_disable_MercuryUnit              ;  機能の無効化
    bsr     disp_MercuryUnit                    ;  機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; MIDI I/F Board 機能の
    btst.b  #1,flag_que_PeripheralDisable       ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_disable_MIDIIFBoard              ;   機能の無効化
    bsr     disp_MIDIIFBoard                    ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; Memory Board 機能の
    btst.b  #0,flag_que_PeripheralDisable       ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_disable_MemoryBoard              ;   機能の無効化
    bsr     disp_MemoryBoard                    ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; 自動メモリ検出機能の
    btst.b  #4,flag_que_PeripheralDisable       ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_disable_AutoMemoryDetection      ;   機能の無効化
    bsr     disp_AutoMemoryDetection            ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:

exec_que_PeripheralEnable:                      ; Mercury Unit 機能の
    btst.b  #2,flag_que_PeripheralEnable        ;  有効無効トグル予約が
    beq     @f                                  ;   されてなければ次へ
    bsr     KX_enable_MercuryUnit               ;  機能の無効化
    bsr     disp_MercuryUnit                    ;  機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; MIDI I/F Board 機能の
    btst.b  #1,flag_que_PeripheralEnable        ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_enable_MIDIIFBoard               ;   機能の無効化
    bsr     disp_MIDIIFBoard                    ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; Memory Board 機能の
    btst.b  #0,flag_que_PeripheralEnable        ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_enable_MemoryBoard               ;   機能の無効化
    bsr     disp_MemoryBoard                    ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:                                             ; 自動メモリ検出機能の
    btst.b  #4,flag_que_PeripheralEnable        ;   有効無効トグル予約が
    beq     @f                                  ;    されてなければ次へ
    bsr     KX_enable_AutoMemoryDetection       ;   機能の無効化
    bsr     disp_AutoMemoryDetection            ;   機能の有効無効表示
    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
@@:

exec_que_set_Volume: 
    btst.b  #7,flag_que_set_Volume              ; S/PDIF(光)入力の音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_SPDIFVolume,d0             ;  音量を
    bsr     KX_set_SPDIFVolume                  ;   設定するよ
    bsr     disp_SPDIFVolume                    ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #7,flag_que_turn_Volume             ; S/PDIF(光)入力の相対音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_SPDIFVolume,d0             ;  音量を
    bsr     KX_turn_SPDIFVolume                 ;   加算するよ
    bsr     disp_SPDIFVolume                    ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #6,flag_que_set_Volume              ; mt32-piの音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_mt32piVolume,d0            ;  音量を
    bsr     KX_set_mt32piVolume                 ;   設定するよ
    bsr     disp_mt32piVolume                   ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #6,flag_que_turn_Volume             ; mt32-pi の相対音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_mt32piVolume,d0            ;  音量を
    bsr     KX_turn_mt32piVolume                ;   加算するよ
    bsr     disp_mt32piVolume                   ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #5,flag_que_set_Volume              ; YM2151の音量が
    beq     @@f                                 ;  予約されてなければ次へ
    bsr     KX_detect_X68030                    ; X68030
    beq     @f                                  ;  なら次へ
    move.b  flag_que_YM2151Volume,d0            ;  音量を
    bsr     KX_set_YM2151Volume                 ;   設定するよ
@@:
    bsr     disp_YM2151Volume                   ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #5,flag_que_turn_Volume             ; YM2151の相対音量が
    beq     @@f                                 ;  予約されてなければ次へ
    bsr     KX_detect_X68030                    ; X68030
    beq     @f                                  ;  なら次へ
    move.b  flag_que_YM2151Volume,d0            ;  音量を
    bsr     KX_turn_YM2151Volume                ;   加算するよ
@@:
    bsr     disp_YM2151Volume                   ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #4,flag_que_set_Volume              ; ADPCMの音量が
    beq     @@f                                 ;  予約されてなければ次へ
    bsr     KX_detect_X68030                    ; X68030
    beq     @f                                  ;  なら次へ
    move.b  flag_que_ADPCMVolume,d0             ;  音量を
    bsr     KX_set_ADPCMVolume                  ;   設定するよ
@@:
    bsr     disp_ADPCMVolume                    ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #4,flag_que_turn_Volume             ; ADPCMの相対音量が
    beq     @@f                                 ;  予約されてなければ次へ
    bsr     KX_detect_X68030                    ; X68030
    beq     @f                                  ;  なら次へ
    move.b  flag_que_ADPCMVolume,d0             ;  音量を
    bsr     KX_turn_ADPCMVolume                 ;   加算するよ
@@:
    bsr     disp_ADPCMVolume                    ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #2,flag_que_set_Volume              ; Mercury Unit FM の音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_MercuryUnitFMVolume,d0     ;  音量を
    bsr     KX_set_MercuryUnitFMVolume          ;   設定するよ
    bsr     disp_MercuryUnitFMVolume            ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #2,flag_que_turn_Volume             ; Mercury Unit FM の相対音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_MercuryUnitFMVolume,d0     ;  音量を
    bsr     KX_turn_MercuryUnitFMVolume         ;   加算するよ
    bsr     disp_MercuryUnitFMVolume            ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #1,flag_que_set_Volume              ; Mercury Unit SSG の音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_MercuryUnitSSGVolume,d0    ;  音量を
    bsr     KX_set_MercuryUnitSSGVolume         ;   設定するよ
    bsr     disp_MercuryUnitSSGVolume           ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #1,flag_que_turn_Volume             ; Mercury Unit SSG の相対音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_MercuryUnitSSGVolume,d0    ;  音量を
    bsr     KX_turn_MercuryUnitSSGVolume        ;   加算するよ
    bsr     disp_MercuryUnitSSGVolume           ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #0,flag_que_set_Volume              ; Mercury Unit PCM の音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_MercuryUnitPCMVolume,d0    ;  音量を
    bsr     KX_set_MercuryUnitPCMVolume         ;   設定するよ
    bsr     disp_MercuryUnitPCMVolume           ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:
    btst.b  #0,flag_que_turn_Volume             ; Mercury Unit PCM の相対音量が
    beq     @f                                  ;  予約されてなければ次へ
    move.b  flag_que_MercuryUnitPCMVolume,d0    ;  音量を
    bsr     KX_turn_MercuryUnitPCMVolume        ;   加算するよ
    bsr     disp_MercuryUnitPCMVolume           ;  音量表示
    bset.b  #6,flag_kxctl                       ;   exec 済みフラグをセット
@@:

exec_que_mt32piControl:
    btst.b  #0,flag_que_mt32piControl           ; mt32-piコントロール予約が
    beq     @f                                  ;  されてなければ次へ
    move.b  flag_que_mt32piCommand,d0           ; mt32-pi に送る SysEx コマンドを入れる
    lsl.w   #8,d0                               ; 8bit 左に詰める
    move.b  flag_que_mt32piParam,d0             ; mt32-pi に送る SysEx パラメータを入れる
    bsr     KX_set_mt32piControl                ; mt32-pi のコントロールレジスタへ書き込む
@@:

exec_que_MIDIRouting:

    move.b  flag_que_MIDIRouting,d1             ; MIDI Routing の予約状況を取得
    cmp.b   #%11,d1                             ; mt32-pi 入力とMIDI外部出力の Routing 予約が同時に
    bne     @f                                  ;  指定されてなければ次へ

    bsr     KX_get_MIDIRouting                  ; MIDI Routing の現状設定を取得
    andi.w  #$FFF0,d0                           ; Reserved bit をマスク
    move.b  flag_que_mt32piInputSource,d1       ; 予約された mt32-pi 入力のソースIDを
    lsl.b   #2,d1                               ; 左へ 2 bit 詰めて
    or.b    d1,d0                               ;  現状設定にあてはめる
    move.b  flag_que_MIDIExtOutSource,d1        ; 予約された MIDI外部出力のソースIDも
    or.b    d1,d0                               ;  あてはめる
    bsr     KX_set_MIDIRouting                  ; MIDI Routing を設定
    bsr     disp_mt32piInputSource              ; mt32-pi 入力ソース表示
    bsr     disp_MIDIExtOutSource               ; MIDI 外部出力ソース表示
    bra     98f                                 ; おしまい
@@:
    btst.l  #1,d1                               ; mt32-pi 入力のソースIDが
    beq     @f                                  ;  予約されてなければ次へ
    
    move.b  flag_que_mt32piInputSource,d0       ; 予約された mt32-pi 入力のソースIDを取得して
    bsr     KX_set_mt32piInputSource            ;  設定するよ
    bsr     disp_mt32piInputSource              ; mt32-pi 入力ソース表示
    bra     98f                                 ; おしまい
@@:
    btst.l  #0,d1                               ; MIDI 外部出力のソースIDが
    beq     99f                                 ;  予約されてなければおしまい
    
    move.b  flag_que_MIDIExtOutSource,d0        ; 予約された MIDI外部出力のソースIDを取得して
    bsr     KX_set_MIDIExtOutSource             ;  設定するよ
    bsr     disp_MIDIExtOutSource               ; MIDI 外部出力ソース表示
98:

    bset.b  #6,flag_kxctl                       ; exec 済みフラグをセット
99:
    rts

;=========================================================================================

disp_all:
    bsr     disp_MemoryBoard                    ; Memory Board 機能の有効無効表示
    bsr     disp_AutoMemoryDetection            ; メモリ自動検出機能の有効無効表示
    bsr     disp_MIDIIFBoard                    ; MIDI I/F Board 機能の有効無効表示
    bsr     disp_MercuryUnit                    ; Mercury Unit 機能の有効無効表示
    bsr     disp_MercuryUnitFMVolume            ; Mercury Unit FM の音量表示
    bsr     disp_MercuryUnitSSGVolume           ; Mercury Unit SSG の音量表示
    bsr     disp_MercuryUnitPCMVolume           ; Mercury Unit PCM の音量表示
    bsr     disp_YM2151Volume                   ; YM2151 の音量表示
    bsr     disp_ADPCMVolume                    ; ADPCM の音量表示
    bsr     disp_mt32piVolume                   ; mt32-pi の音量表示
    bsr     disp_SPDIFVolume                    ; S/PDIF の音量表示
;    bsr     disp_mt32piOutInputStatus           ; mt32-pi 出力からの入力検出状態表示
;    bsr     disp_SPDIFInInputStatus             ; S/PDIF(光)入力からの入力検出状態表示
    bsr     disp_mt32piInputSource              ; mt32-pi 入力ソース表示
    bsr     disp_MIDIExtOutSource               ; MIDI 外部出力ソース表示
    bsr     disp_SystemClockFreq                ; SystemClock表示
    bsr     disp_HSyncFreq                      ; 水平同期(H-Sync) 実測値表示
    bsr     disp_VSyncFreq                      ; 垂直同期(V-Sync) 実測値表示
    bsr     disp_Human68kSUPERVISORArea         ; Human68k の SUPERVISOR エリア表示

    rts

;=========================================================================================

disp_border:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   mes_border                          ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_Title:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    bsr     mlib_printtitle                     ; Title 表示

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_delimiter:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   mes_delimiter                       ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_Version:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    move.w  #$0006,d0                           ; $5 = $1(水色) + $4(太字)
    lea.l   label_Version,a0                    ; KeplerX を
    bsr     mlib_cprint                         ;  表示するよ

    move.w  #$0005,d0                           ; $7 = $3(白色) + $4(太字)
    bsr     KX_get_VersionCodeName              ; バージョンコード名を取得して
    bsr     mlib_cprint

    move.w  #' ',-(sp)                          ; ' ' を
    DOS     _PUTCHAR                            ;  表示するよ
    addq.l  #2,sp

    move.w  #$0007,d0                           ; $6 = $3(黄色) + $4(太字)
    bsr     KX_get_PatchVersionName             ; パッチバージョン名を取得して
    bsr     mlib_cprint

    move.w     #$0003,d0                        ; $3(白)
    lea.l      mlib_crlf,a0                     ; 改行を
    bsr        mlib_cprint                      ;  表示するよ
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MemoryBoard:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MemoryBoard                   ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_check_MemoryBoard                ; Mercury Board 機能の有効無効を
    bsr     disp_Peripheral                     ;  表示するよ

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_AutoMemoryDetection:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_AutoMemoryDetection           ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_check_AutoMemoryDetection        ; メモリの自動検出機能の有効無効を取得して
    bsr     disp_Peripheral                     ;  表示するよ

    pea.l   mes_ExpansionMemory_B               ; '(+' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_ExpandedMemorySize           ; 増設されたメモリのサイズを取得して
    andi.l  #$0000FFFF,d0                       ;  32bit化して
    bsr     mlib_printdec                       ;  表示するよ

    pea.l   mes_ExpansionMemory_F               ; 'MB)' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MIDIIFBoard:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MIDIIFBoard                   ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_check_MIDIIFBoard                ; MIDI I/F Board 機能の有効無効を
    bsr     disp_Peripheral                     ;  表示するよ

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MercuryUnit:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MercuryUnit                   ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_check_MercuryUnit                ; Mercury Unit 機能の有効無効を
    bsr     disp_Peripheral                     ;  表示するよ

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MercuryUnitFMVolume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MercuryUnitFMVolume           ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_MercuryUnitFMVolume          ; Mercury Unit FM の音量を
    bsr     disp_Volume                         ;  表示するよ

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MercuryUnitSSGVolume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MercuryUnitSSGVolume          ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_MercuryUnitSSGVolume         ; Mercury Unit SSG の音量を
    bsr     disp_Volume                         ;  表示するよ

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MercuryUnitPCMVolume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MercuryUnitPCMVolume          ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_MercuryUnitPCMVolume         ; Mercury Unit PCM の音量を
    bsr     disp_Volume                         ;  表示するよ

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_YM2151Volume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_YM2151Volume                  ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_detect_X68030                    ; X68030
    beq     @f                                  ;  なら次へ

    bsr     KX_get_YM2151Volume                 ; YM2151 の音量を
    bsr     disp_Volume                         ;  表示するよ
    bra     @@f                                 ; 次へ
@@:
    pea     mes_cannotEmulate                   ; 「エミュレートできません」を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

@@:
    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_ADPCMVolume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_ADPCMVolume                   ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_detect_X68030                    ; X68030
    beq     @f                                  ;  なら次へ

    bsr     KX_get_ADPCMVolume                  ; ADPCM の音量を
    bsr     disp_Volume                         ;  表示するよ
    bra     @@f                                 ; 次へ
@@:
    pea     mes_cannotEmulate                   ; 「エミュレートできません」を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

@@:
    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_mt32piVolume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_mt32piVolume               ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_mt32piVolume              ; S/PDIFの音量を
    bsr     disp_Volume                         ;  表示するよ

    move.w  #' ',-(sp)                          ; ' ' を
    DOS     _PUTCHAR                            ;  表示するよ
    addq.l  #2,sp

    bsr     KX_get_mt32piOutInputStatusName     ; mt32-pi 出力からの入力検出状態を取得して
    move.l  a0,-(sp)                            ; それを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_SPDIFVolume:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_SPDIFVolume                   ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_SPDIFVolume                  ; S/PDIFの音量を
    bsr     disp_Volume                         ;  表示するよ

    move.w  #' ',-(sp)                          ; ' ' を
    DOS     _PUTCHAR                            ;  表示するよ
    addq.l  #2,sp

    bsr     KX_get_SPDIFInInputStatusName       ; S/PDIF(光)入力からの入力検出状態を取得して
    move.l  a0,-(sp)                            ; それを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts


;-----------------------------------------------------------------------------------------
;
;disp_mt32piOutInputStatus:
;    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
;    bne     99f                                 ; オンならおしまい
;
;    pea.l   label_mt32piOutInputStatus          ; ラベルを
;    DOS     _PRINT                              ;  表示するよ
;    addq.l  #4,sp
;
;    bsr     KX_get_mt32piOutInputStatusName     ; mt32-pi 出力からの入力検出状態を取得して
;    move.l  a0,-(sp)                            ; それを
;    DOS     _PRINT                              ;  表示するよ
;    addq.l  #4,sp
;
;    pea.l   mlib_crlf                           ; 改行を
;    DOS     _PRINT                              ;  表示するよ
;    addq.l  #4,sp
;99:
;    rts
;
;-----------------------------------------------------------------------------------------
;
;disp_SPDIFInInputStatus:
;    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
;    bne     99f                                 ; オンならおしまい
;
;    pea.l   label_SPDIFInInputStatus            ; ラベルを
;    DOS     _PRINT                              ;  表示するよ
;    addq.l  #4,sp
;
;    bsr     KX_get_SPDIFInInputStatusName       ; S/PDIF(光)入力からの入力検出状態を取得して
;    move.l  a0,-(sp)                            ; それを
;    DOS     _PRINT                              ;  表示するよ
;    addq.l  #4,sp
;
;    pea.l   mlib_crlf                           ; 改行を
;    DOS     _PRINT                              ;  表示するよ
;    addq.l  #4,sp
;99:
;    rts
;
;-----------------------------------------------------------------------------------------

disp_mt32piInputSource:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_mt32piInputSource             ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_mt32piInputSourceName        ; mt32-pi 入力ソースを取得して
    move.l  a0,-(sp)                            ; それを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_MIDIExtOutSource:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_MIDIExtOutSource              ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_MIDIExtOutSourceName         ; MIDI 外部出力ソースを取得して
    move.l  a0,-(sp)                            ; それを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_SystemClockFreq:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_SystemClockFreq               ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_SystemClockFreq              ; X68K本体のシステムクロックの実測値を取得して
    move.l  #3,d1                               ;  小数点以下 3 桁で
    bsr     mlib_printfloat                     ;  表示するよ

    pea.l   mes_MHz                             ; 'MHz' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_HSyncFreq:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_HSyncFreq                     ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_HSyncFreq                    ; 水平同期(H-Sync) 実測値を取得して
    move.l  #3,d1                               ;  小数点以下 3 桁で
    bsr     mlib_printfloat                     ;  表示するよ

    pea.l   mes_KHz                             ; 'KHz' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_VSyncFreq:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_VSyncFreq                     ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_VSyncFreq                    ; 垂直同期(V-Sync) 実測値を取得して
    move.l  #1,d1                               ;  小数点以下 1 桁で
    bsr     mlib_printfloat                     ;  表示するよ

    pea.l   mes_Hz                              ; 'Hz' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_Human68kSUPERVISORArea:

    bsr     KX_detect_X68030                    ; X68030
    beq     99f                                 ;  ならおしまい

    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   label_Human68kSUPERVISORArea        ; ラベルを
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bsr     KX_get_Human68kSUPERVISORSize       ; Human68k の SUPERVISOR エリアサイズを取得
    subq.l  #1,d0                               ; 最終アドレスに変換
    bmi     @f                                  ;  負になったら次へ
    bsr     mlib_printhex                       ; 表示するよ
@@:
    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_crlf:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_NotDetected:

    bsr     disp_Title                          ; Title 表示

    pea.l   KX_Name                             ; 「KeplerX」を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    pea.l   mes_NotDetected                     ; 「検出できませんでした」
    DOS     _PRINT                              ;  を表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    rts

;-----------------------------------------------------------------------------------------

disp_Peripheral:
    tst.l   d0                                  ; d0 が
    beq     @f                                  ; 0 なら次へ

    pea.l   mes_PeripheralEnable                ; 'enable' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp

    bra     99f                                 ; おしまい
@@:
    pea.l   mes_PeripheralDisable               ; 'disable' を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;-----------------------------------------------------------------------------------------

disp_Volume:

    move.l     a6,-(sp)                         ; a6 を退避

    and.l      #$0F,d0                          ; 最下位 4bit のみマスク
    lsl.b      #4,d0                            ; 16倍してオフセット値へ変換
    lea.l      mes_volume,a6                    ; 音量表示文字列のアドレス
    add.l      d0,a6                            ; 音量表示文字列にオフセット値を加算
    move.l     a6,-(sp)                         ; 音量表示文字列を
    DOS        _PRINT                           ;  表示するよ
    addq.l     #4,sp

    move.l     (sp)+,a6                         ; a6 を復元
    rts

;-----------------------------------------------------------------------------------------

disp_Help:
    btst.b  #7,flag_kxctl                       ; quiet モードフラグが
    bne     99f                                 ; オンならおしまい

    bsr     disp_Title                          ; Title 表示

    pea.l   mes_help                            ; ヘルプ
    DOS     _PRINT                              ;  を表示するよ
    addq.l  #4,sp

    pea.l   mlib_crlf                           ; 改行を
    DOS     _PRINT                              ;  表示するよ
    addq.l  #4,sp
99:
    rts

;=========================================================================================

    .data
    .even

;-----------------------------------------------------------------------------------------

mlib_title::
    .dc.b   'KXCTL ',$00
mlib_version::
    .dc.b   $F3,'v',$F3,'e',$F3,'r',$F3,'s',$F3,'i',$F3,'o',$F3,'n',$F3,' '
    .dc.b   $F3,'1',$F3,'.',$F3,'0',$F3,'1',$F3,' ',$00
mlib_by::
    .dc.b   ' ',$F3,'b',$F3,'y ',$00
mlib_author::
    .dc.b   'みゆ (miyu rose)',$00

mes_help:
    .dc.b   ' kxctl.x [options] ([options]...)',$0D,$0A
    .dc.b   '  [options]',$0D,$0A
    .dc.b   '   -[muni|midi|memb|memd]=[1|0]                     : Enable or Disable ',$0D,$0A
    .dc.b   '   -[muni|midi|memb|memd]+                          : Toggle Enable     ',$0D,$0A
    .dc.b   '   -[mufm|mssg|mpcm|x6fm|x6ad|mt32|spdf]=[0～F]     : Set volume',$0D,$0A
    .dc.b   '   -[mufm|mssg|mpcm|x6fm|x6ad|mt32|spdf]=[-8～+7]   : Set volume from 100%',$0D,$0A
;    .dc.b   '   -[mufm|mssg|mpcm|x6fm|x6ad|mt32|spdf]+           : Toggle mute ',$0D,$0A
    .dc.b   '   -[mufm|mssg|mpcm|x6fm|x6ad|mt32|spdf][+|-][0～F] : Turn volume up or down',$0D,$0A
    .dc.b   '   -mt32:[Command(2 digit HEX)][Param(2 digit HEX)] : mt32-pi Control',$0D,$0A
    .dc.b   '   -mtin=[0|none|1|miot|2|mxin]                     : Source of mt32-pi-In',$0D,$0A
    .dc.b   '   -mxot=[0|none|1|miot|2|mxin]                     : Source of MIDI Ext-Out',$0D,$0A
    .dc.b   '   -q                                               : Quiet mode',$0D,$0A
    .dc.b   $0D,$0A
    .dc.b   '    muni: Mercury Unit, midi: MIDI I/F Board',$0D,$0A
    .dc.b   '    memb: Memory Board, memd: Auto Memory Detection',$0D,$0A
    .dc.b   '    mufm: Mercury FM, mssg: Mercury SSG, mpcm: Mercury PCM',$0D,$0A
    .dc.b   '    x6fm: X68K YM2151, x6ad: X68K ADPCM, mt32: mt32-pi, spdf: S/PDIF',$0D,$0A
    .dc.b   '    none: None, miot: MIDI I/F Out, mxin: MIDI Ext-In',$0D,$0A
    .dc.b   $00

mes_NotDetected:
    .dc.b   ' could not be detected.',$0D,$0A,$00

mes_PeripheralEnable:
    .dc.b   'enable',$00
mes_PeripheralDisable:
    .dc.b   'disable',$00
mes_ExpansionMemory_B:
    .dc.b   ' (+',$00
mes_ExpansionMemory_F:
    .dc.b   'MB)',$00
mes_MHz:
    .dc.b   'MHz',$00
mes_KHz:
    .dc.b   'KHz',$00
mes_Hz:
    .dc.b   'Hz',$00
mes_cannotEmulate:
    .dc.b   'cannot emulate',$00
mes_volume:
    .dc.b   '[8] 100.0% (+0)',$00
    .dc.b   '[9] 112.5% (+1)',$00
    .dc.b   '[A] 125.0% (+2)',$00
    .dc.b   '[B] 137.5% (+3)',$00
    .dc.b   '[C] 150.0% (+4)',$00
    .dc.b   '[D] 162.5% (+5)',$00
    .dc.b   '[E] 175.0% (+6)',$00
    .dc.b   '[F] 187.5% (+7)',$00
    .dc.b   '[0]   0.0% (-8)',$00
    .dc.b   '[1]  12.5% (-7)',$00
    .dc.b   '[2]  25.0% (-6)',$00
    .dc.b   '[3]  37.5% (-5)',$00
    .dc.b   '[4]  50.0% (-4)',$00
    .dc.b   '[5]  62.5% (-3)',$00
    .dc.b   '[6]  75.0% (-2)',$00
    .dc.b   '[7]  87.5% (-1)',$00

mes_delimiter:
    .dc.b   '-----------------------------------------------',$0D,$0A,$00
label_Version:
    .dc.b   '               KeplerX ',$00
label_MemoryBoard:
    .dc.b   '  Expansion Memory Board：',$00
label_AutoMemoryDetection:
    .dc.b   '   Memory Auto Detection：',$00
label_MIDIIFBoard:
    .dc.b   '          MIDI I/F Board：',$00
label_MercuryUnit:
    .dc.b   '            Mercury Unit：',$00
label_MercuryUnitFMVolume:
    .dc.b   ' Mercury Unit  FM Volume：',$00
label_MercuryUnitSSGVolume:
    .dc.b   ' Mercury Unit SSG Volume：',$00
label_MercuryUnitPCMVolume:
    .dc.b   ' Mercury Unit PCM Volume：',$00
label_YM2151Volume:
    .dc.b   '      X68K YM2151 Volume：',$00
label_ADPCMVolume:
    .dc.b   '      X68K  ADPCM Volume：',$00
label_mt32piVolume:
    .dc.b   '          mt32-pi Volume：',$00
label_SPDIFVolume:
    .dc.b   '      S/PDIF-Thru Volume：',$00
;label_mt32piOutInput:
;    .dc.b  '   mt32-pi-Out Frequency：',$00
;label_SPDIFInInput:
;    .dc.b  '     S/PDIF-In Frequency：',$00
label_mt32piInputSource:
    .dc.b   '       mt32-pi-In Source：',$00
label_MIDIExtOutSource:
    .dc.b   '     MIDI Ext-Out Source：',$00
label_SystemClockFreq:
    .dc.b   '  System Clock Frequency：',$00
label_HSyncFreq:
    .dc.b   '        H-Sync Frequency：',$00
label_VSyncFreq:
    .dc.b   '        V-Sync Frequency：',$00
label_Human68kSUPERVISORArea:
    .dc.b   'Human68k SUPERVISOR Area：$00000000～$',$00
mes_border:
    .dc.b   '===============================================',$0D,$0A,$00

;-----------------------------------------------------------------------------------------

    .bss
    .even

;-----------------------------------------------------------------------------------------

flag_kxctl:                                     ; bit76543210
    .ds.b   1                                   ;   %10000000 quiet モード
                                                ;   %01000000 exec 済フラグ

flag_que_PeripheralEnable:                      ; bit76543210
    .ds.b   1                                   ;   %00010000 メモリ自動検出機能予約
                                                ;   %00000100 Mercury Unit 機能予約
                                                ;   %00000010 MIDI I/F Board 機能予約
                                                ;   %00000001 Memory Board 機能予約
flag_que_PeripheralDisable:                     ; bit76543210
    .ds.b   1                                   ;   %00010000 メモリ自動検出機能予約
                                                ;   %00000100 Mercury Unit 機能予約
                                                ;   %00000010 MIDI I/F Board 機能予約
                                                ;   %00000001 Memory Board 機能予約
flag_que_PeripheralToggle:                      ; bit76543210
    .ds.b   1                                   ;   %00010000 メモリ自動検出機能予約
                                                ;   %00000100 Mercury Unit 機能予約
                                                ;   %00000010 MIDI I/F Board 機能予約
                                                ;   %00000001 Memory Board 機能予約

flag_que_set_Volume:                            ; bit76543210
    .ds.b   1                                   ;   %10000000 S/PDIF(光)入力の音量予約
    .ds.b   1                                   ;   %01000000 mt32-pi の音量予約
    .ds.b   1                                   ;   %00100000 YM2151 の音量予約
    .ds.b   1                                   ;   %00010000 ADPCM の音量予約
    .ds.b   1                                   ;   %00000100 Mercury Unit FM の音量予約
    .ds.b   1                                   ;   %00000010 Mercury Unit SSG の音量予約
    .ds.b   1                                   ;   %00000001 Mercury Unit PSG の音量予約
flag_que_turn_Volume:                           ; bit76543210
    .ds.b   1                                   ;   %10000000 S/PDIF(光)入力の相対音量予約
    .ds.b   1                                   ;   %01000000 mt32-pi の相対音量予約
    .ds.b   1                                   ;   %00100000 YM2151 の相対音量予約
    .ds.b   1                                   ;   %00010000 ADPCM の相対音量予約
    .ds.b   1                                   ;   %00000100 Mercury Unit FM の相対音量予約
    .ds.b   1                                   ;   %00000010 Mercury Unit SSG の相対音量予約
    .ds.b   1                                   ;   %00000001 Mercury Unit PSG の相対音量予約
flag_que_SPDIFVolume:                           ; bit76543210 S/PDIF(光)入力の
    .ds.b   1                                   ;   %0000xxxx  音量指定
                                                ;   %xxxxxxxx  相対音量指定
flag_que_mt32piVolume:                          ; bit76543210 mt32-pi の
    .ds.b   1                                   ;   %0000xxxx  音量指定
                                                ;   %xxxxxxxx  相対音量指定
flag_que_YM2151Volume:                          ; bit76543210 YM2151 の
    .ds.b   1                                   ;   %0000xxxx  音量指定
                                                ;   %xxxxxxxx  相対音量指定
flag_que_ADPCMVolume:                           ; bit76543210 ADPCM
    .ds.b   1                                   ;   %0000xxxx  音量指定
                                                ;   %xxxxxxxx  相対音量指定
flag_que_MercuryUnitFMVolume:                   ; bit76543210 Mercury FM
    .ds.b   1                                   ;   %0000xxxx  音量指定
                                                ;   %xxxxxxxx  相対音量指定
flag_que_MercuryUnitSSGVolume:                  ; bit76543210 Mercury SSG
    .ds.b   1                                   ;   %0000xxxx  音量指定
                                                ;   %xxxxxxxx  相対音量指定
flag_que_MercuryUnitPCMVolume:                  ; bit76543210 Mercury PCM
    .ds.b   1                                   ;   %000xxxxx Mercury PCM の音量指定

flag_que_mt32piControl:                         ; bit76543210
    .ds.b   1                                   ;   %00000001 mt32-piコントロール予約
flag_que_mt32piCommand:                         ; bit76543210
    .ds.b   1                                   ;   %xxxxxxxx mt32-pi SysEx コマンド
flag_que_mt32piParam:                           ; bit76543210
    .ds.b   1                                   ;   %xxxxxxxx mt32-pi SysEx パラメータ

flag_que_MIDIRouting:                           ; bit76543210
    .ds.b   1                                   ;   %00000010 mt32-pi 入力ソース予約
    .ds.b   1                                   ;   %00000001 MIDI外部出力ソース予約

flag_que_mt32piInputSource:                     ; bit76543210
    .ds.b   1                                   ;   %000000xx mt32-pi 入力ソースID指定
flag_que_MIDIExtOutSource:                      ; bit76543210
    .ds.b   1                                   ;   %000000xx MIDI外部出力ソースID指定

;-----------------------------------------------------------------------------------------

    .stack
    .even

;-----------------------------------------------------------------------------------------

mystack:
    .ds.l   1024
mysp:
    .end    main

;=========================================================================================
