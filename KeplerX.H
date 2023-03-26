.ifdef __DEBUG__
_KX_REG    .equ     $00A00000
.else
_KX_REG    .equ     $00ECB000
.endif

    .offset 0

_KX_ID:
    .ds.w   1       ; $ECB000 REG0: ID (read only)
                    ; ASCIIで 'KX' (0x4b58) が読み出せます (これでKeplerXの判定ができます)
                    ;   bit 15-8 : x'4b' (ascii code of 'K')
                    ;   bit  7-0 : x'58' (ascii code of 'X')
_KX_Version:
    .ds.w   1       ; $ECB002 REG1: Version (read only)
                    ; 基板のバージョンです（が、今のところただの定数です）
                    ;   bit 15-8 : reserved (all 0)
                    ;   bit  7-4 : version code ('0': 零, '1': 壱號機, '2': 弍號機)
                    ;   bit  3-0 : patch version (usually it is 0)
_KX_ExpansionMemory:
    .ds.w   1       ; $ECB004 REG2: Expansion Memory Enable flags ('1': enable, '0': disable)
                    ; READすると、増設メモリの有効状態が見られます。
                    ; WRITEすると、増設メモリの有効無効を変更できます。
                    ;   bit 15-12 : reserved
                    ;   bit 11- 2 : 2MB-12MBの拡張状態です。自動検出がONになっていると、アクセスがあったタイミングで自動で1にセットされます
                    ;               ext mem block enable flags (if bit0 is '1' these will be overridden) (default value = '0')
                    ;     bit 11 is for 0xbxxxxx block
                    ;     bit 10 is for 0xaxxxxx block
                    ;     bit  2 is for 0x2xxxxx block
                    ;   bit  1    : 1MB機の1MB-2MB領域の拡張をするかのスイッチです (まだうまく動いていません)
                    ;               ext mem block enable flag for 0x1xxxxx block (default value = DE0Nano DipSw(1) )
                    ;   bit  0    : メモリの自動検出機能で、IP-SW(0)をONにしておくと'1'になって、メモリの自動検出機能がONになります
                    ;               ext mem auto detect flag for 0x2xxxxx - 0xbxxxxx blocks (default value = DE0Nano DipSw(0))
_KX_Peripheral:
    .ds.w   1       ; $ECB006 REG3: Peripheral Enable flags ('1': enable, '0': disable)
                    ; Mercury Unit、MIDI I/F Board、Memory Board の機能をそれぞれ個別に ON/Off できます
                    ;   bit 15- 3 : reserved
                    ;   bit  2    : Mercury Unit (default value = '1')
                    ;   bit  1    : MIDI I/F Board(default value = '1')
                    ;   bit  0    : Memory Board (defaul value = '1')
_KX_SoundVolume1:
    .ds.w   1       ; $ECB008 REG4: Sound Volume Adjust 1 (every 4 bits: (+7～-7)/8, -8 is mute)
                    ; S/PDIF(光)入力、mt32-pi、YM2151、ADPCM の音量調整レジスタです
                    ;   bit 15-12 : S/PDIF in
                    ;   bit 11- 8 : mt32-pi
                    ;   bit  7- 4 : YM2151
                    ;   bit  3- 0 : ADPCM
_KX_SoundVolume2:
    .ds.w   1       ; $ECB00A REG5: Sound Volume Adjust 2 (every 4 bits: (+7～-7)/8, -8 is mute)
                    ; Mercury Unit の音量調整レジスタです
                    ;   bit 15-12 : reserved
                    ;   bit 11- 8 : Mercury Unit FM
                    ;   bit  7- 4 : Mercury Unit SSG
                    ;   bit  3- 0 : Mercury Unit PCM
_KX_SoundInputStatus:
    .ds.w   1       ; $ECB00C REG6: Sound Input Status (read only)
                    ; 外部音源入力の入力検出状態を調べます (無音でも検出されます)
                    ;   bit 15-8 : reserved (all 0)
                    ;   bit  7-4 : mt32-pi 出力からの入力検出です（このビットが '0011' の時は、mt32-piが正常に動いているとわかります）
                    ;              mt32-pi input detect  (0: None, 1: 32kHz, 2: 44.1kHz, 3: 48kHz, 4: 96kHz) ※ 48kHz以外はまだサポート外
                    ;   bit  3-0 : S/PDIF(光)入力からの入力検出です（今は常に '0011' になってしまいます）
                    ;              S/PDIF input detect (0: None, 1: 32kHz, 2: 44.1kHz, 3: 48kHz, 4: 96kHz) ※ 48kHz以外はまだサポート外 
                    ;
    .ds.w   1       ; $ECB00E REG7: Reserved1
_KX_MIDIRouting:
    .ds.w   1       ; $ECB010 REG8: MIDI Routing
                    ; MIDIのルーティング（接続）変更レジスタです
                    ;
                    ;   MIDI I/F-Out ─→ MIDI Ext-Out
                    ;    ↑      ↓        (↑)
                    ;    │ mt32-pi Input  (│)
                    ;    │     (↑)       (│)
                    ;    └───┴─── MIDI Ext-In
                    ;
                    ;   bit 3-2 : mt32-pi Input source ('00': None, '01': MIDI I/F-Out, '10': MIDI Ext-In, '11': Reserved) (default value = '01')
                    ;   bit 1-0 : MIDI Ext-Out source  ('00': None, '01': MIDI I/F-Out, '10': MIDI Ext-In, '11': Reserved) (default value = '01')
_KX_mt32piControl:
    .ds.w   1       ; $ECB012 REG9: mt32-pi control
                    ; mt32-piのコントロールレジスタです (https://github.com/dwhinham/mt32-pi/wiki/Custom-System-Exclusive-messages)
                    ;   [WRITE]
                    ;      bit 15-12 : reserved
                    ;      bit 11- 8 : command
                    ;                   01 : Switch MT-32 ROM set
                    ;                         param : '00'=MT-32(old)、'01'=MT-32(new)、'02'=CM-32L
                    ;                   02 : Switch SoundFont
                    ;                         param : Zero-based index into contents of soundfonts directory (lexicographically sorted).
                    ;                   03 : Switch Synthesizer
                    ;                         param : '00'=MT-32 ROM、'01'=SoundFont
                    ;                   04 : MT-32 reversed stereo
                    ;                         param : '00'=Disabled、'01'=Enabled (panpot CC values are inverted)
                    ;      bit  7- 0 : param
                    ;   [READ]
                    ;      bit 15    : busy
                    ;      bit 14- 0 : reserved
    .ds.w   1       ; $ECB014 REG10: Reserved2
    .ds.w   1       ; $ECB016 REG11: Reserved3
_KX_SystemClockFreq:
    .ds.w   1       ; $ECB018 REG12: System Clock Freq (KHz) (read only)
                    ; X68K本体のシステムクロックの実測値です (単位はKHz)
                    ; ノーマルクロックの 10MHz は 10000kHz なので 0x2710 で、OC していれば違う値となります
_KX_HSyncFreq:
    .ds.w   1       ; $ECB01A REG13: H Sync Freq (Hz) (read only)
                    ; 水平同期(H-Sync) 実測値(毎秒更新)です (単位はHz)
                    ; 31.5KHz なら 31500Hz なので 0x7B0C です
_KX_VSyncFreq:
    .ds.w   1       ; $ECB01C REG14: V Sync Freq (0.1Hz) (read only)
                    ; 垂直同期(V-Sync) 実測値(10秒毎更新)です (単位は0.1Hz)
                    ; 55Hz なら 550×0.1Hz なので 0x0226 です
_KX_AreaSetRegisterCache:
    .ds.w   1       ; $ECB01E REG15: Area Set register cache (for $E86000) (read only)
                    ; Human68k が Area Set レジスタ $E86001 に書き込んだ値を盗み見て、メモしておくレジスタです (X68030では無効)
                    ; Area Set レジスタは Write Only なので何を書いたかわからないのですが、ここを読むことで
                    ; 0 番地から ((この値+1)×8192-1) 番地までのアドレスが Human68k の SUPERVISOR 領域となっていることがわかります
