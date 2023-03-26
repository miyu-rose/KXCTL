.ifdef __DEBUG__
_KX_REG    .equ     $00A00000
.else
_KX_REG    .equ     $00ECB000
.endif

    .offset 0

_KX_ID:
    .ds.w   1       ; $ECB000 REG0: ID (read only)
                    ; ASCII�� 'KX' (0x4b58) ���ǂݏo���܂� (�����KeplerX�̔��肪�ł��܂�)
                    ;   bit 15-8 : x'4b' (ascii code of 'K')
                    ;   bit  7-0 : x'58' (ascii code of 'X')
_KX_Version:
    .ds.w   1       ; $ECB002 REG1: Version (read only)
                    ; ��̃o�[�W�����ł��i���A���̂Ƃ��낽���̒萔�ł��j
                    ;   bit 15-8 : reserved (all 0)
                    ;   bit  7-4 : version code ('0': ��, '1': ���j�@, '2': ���j�@)
                    ;   bit  3-0 : patch version (usually it is 0)
_KX_ExpansionMemory:
    .ds.w   1       ; $ECB004 REG2: Expansion Memory Enable flags ('1': enable, '0': disable)
                    ; READ����ƁA���݃������̗L����Ԃ������܂��B
                    ; WRITE����ƁA���݃������̗L��������ύX�ł��܂��B
                    ;   bit 15-12 : reserved
                    ;   bit 11- 2 : 2MB-12MB�̊g����Ԃł��B�������o��ON�ɂȂ��Ă���ƁA�A�N�Z�X���������^�C�~���O�Ŏ�����1�ɃZ�b�g����܂�
                    ;               ext mem block enable flags (if bit0 is '1' these will be overridden) (default value = '0')
                    ;     bit 11 is for 0xbxxxxx block
                    ;     bit 10 is for 0xaxxxxx block
                    ;     bit  2 is for 0x2xxxxx block
                    ;   bit  1    : 1MB�@��1MB-2MB�̈�̊g�������邩�̃X�C�b�`�ł� (�܂����܂������Ă��܂���)
                    ;               ext mem block enable flag for 0x1xxxxx block (default value = DE0Nano DipSw(1) )
                    ;   bit  0    : �������̎������o�@�\�ŁAIP-SW(0)��ON�ɂ��Ă�����'1'�ɂȂ��āA�������̎������o�@�\��ON�ɂȂ�܂�
                    ;               ext mem auto detect flag for 0x2xxxxx - 0xbxxxxx blocks (default value = DE0Nano DipSw(0))
_KX_Peripheral:
    .ds.w   1       ; $ECB006 REG3: Peripheral Enable flags ('1': enable, '0': disable)
                    ; Mercury Unit�AMIDI I/F Board�AMemory Board �̋@�\�����ꂼ��ʂ� ON/Off �ł��܂�
                    ;   bit 15- 3 : reserved
                    ;   bit  2    : Mercury Unit (default value = '1')
                    ;   bit  1    : MIDI I/F Board(default value = '1')
                    ;   bit  0    : Memory Board (defaul value = '1')
_KX_SoundVolume1:
    .ds.w   1       ; $ECB008 REG4: Sound Volume Adjust 1 (every 4 bits: (+7�`-7)/8, -8 is mute)
                    ; S/PDIF(��)���́Amt32-pi�AYM2151�AADPCM �̉��ʒ������W�X�^�ł�
                    ;   bit 15-12 : S/PDIF in
                    ;   bit 11- 8 : mt32-pi
                    ;   bit  7- 4 : YM2151
                    ;   bit  3- 0 : ADPCM
_KX_SoundVolume2:
    .ds.w   1       ; $ECB00A REG5: Sound Volume Adjust 2 (every 4 bits: (+7�`-7)/8, -8 is mute)
                    ; Mercury Unit �̉��ʒ������W�X�^�ł�
                    ;   bit 15-12 : reserved
                    ;   bit 11- 8 : Mercury Unit FM
                    ;   bit  7- 4 : Mercury Unit SSG
                    ;   bit  3- 0 : Mercury Unit PCM
_KX_SoundInputStatus:
    .ds.w   1       ; $ECB00C REG6: Sound Input Status (read only)
                    ; �O���������͂̓��͌��o��Ԃ𒲂ׂ܂� (�����ł����o����܂�)
                    ;   bit 15-8 : reserved (all 0)
                    ;   bit  7-4 : mt32-pi �o�͂���̓��͌��o�ł��i���̃r�b�g�� '0011' �̎��́Amt32-pi������ɓ����Ă���Ƃ킩��܂��j
                    ;              mt32-pi input detect  (0: None, 1: 32kHz, 2: 44.1kHz, 3: 48kHz, 4: 96kHz) �� 48kHz�ȊO�͂܂��T�|�[�g�O
                    ;   bit  3-0 : S/PDIF(��)���͂���̓��͌��o�ł��i���͏�� '0011' �ɂȂ��Ă��܂��܂��j
                    ;              S/PDIF input detect (0: None, 1: 32kHz, 2: 44.1kHz, 3: 48kHz, 4: 96kHz) �� 48kHz�ȊO�͂܂��T�|�[�g�O 
                    ;
    .ds.w   1       ; $ECB00E REG7: Reserved1
_KX_MIDIRouting:
    .ds.w   1       ; $ECB010 REG8: MIDI Routing
                    ; MIDI�̃��[�e�B���O�i�ڑ��j�ύX���W�X�^�ł�
                    ;
                    ;   MIDI I/F-Out ���� MIDI Ext-Out
                    ;    ��      ��        (��)
                    ;    �� mt32-pi Input  (��)
                    ;    ��     (��)       (��)
                    ;    ���������������� MIDI Ext-In
                    ;
                    ;   bit 3-2 : mt32-pi Input source ('00': None, '01': MIDI I/F-Out, '10': MIDI Ext-In, '11': Reserved) (default value = '01')
                    ;   bit 1-0 : MIDI Ext-Out source  ('00': None, '01': MIDI I/F-Out, '10': MIDI Ext-In, '11': Reserved) (default value = '01')
_KX_mt32piControl:
    .ds.w   1       ; $ECB012 REG9: mt32-pi control
                    ; mt32-pi�̃R���g���[�����W�X�^�ł� (https://github.com/dwhinham/mt32-pi/wiki/Custom-System-Exclusive-messages)
                    ;   [WRITE]
                    ;      bit 15-12 : reserved
                    ;      bit 11- 8 : command
                    ;                   01 : Switch MT-32 ROM set
                    ;                         param : '00'=MT-32(old)�A'01'=MT-32(new)�A'02'=CM-32L
                    ;                   02 : Switch SoundFont
                    ;                         param : Zero-based index into contents of soundfonts directory (lexicographically sorted).
                    ;                   03 : Switch Synthesizer
                    ;                         param : '00'=MT-32 ROM�A'01'=SoundFont
                    ;                   04 : MT-32 reversed stereo
                    ;                         param : '00'=Disabled�A'01'=Enabled (panpot CC values are inverted)
                    ;      bit  7- 0 : param
                    ;   [READ]
                    ;      bit 15    : busy
                    ;      bit 14- 0 : reserved
    .ds.w   1       ; $ECB014 REG10: Reserved2
    .ds.w   1       ; $ECB016 REG11: Reserved3
_KX_SystemClockFreq:
    .ds.w   1       ; $ECB018 REG12: System Clock Freq (KHz) (read only)
                    ; X68K�{�̂̃V�X�e���N���b�N�̎����l�ł� (�P�ʂ�KHz)
                    ; �m�[�}���N���b�N�� 10MHz �� 10000kHz �Ȃ̂� 0x2710 �ŁAOC ���Ă���ΈႤ�l�ƂȂ�܂�
_KX_HSyncFreq:
    .ds.w   1       ; $ECB01A REG13: H Sync Freq (Hz) (read only)
                    ; ��������(H-Sync) �����l(���b�X�V)�ł� (�P�ʂ�Hz)
                    ; 31.5KHz �Ȃ� 31500Hz �Ȃ̂� 0x7B0C �ł�
_KX_VSyncFreq:
    .ds.w   1       ; $ECB01C REG14: V Sync Freq (0.1Hz) (read only)
                    ; ��������(V-Sync) �����l(10�b���X�V)�ł� (�P�ʂ�0.1Hz)
                    ; 55Hz �Ȃ� 550�~0.1Hz �Ȃ̂� 0x0226 �ł�
_KX_AreaSetRegisterCache:
    .ds.w   1       ; $ECB01E REG15: Area Set register cache (for $E86000) (read only)
                    ; Human68k �� Area Set ���W�X�^ $E86001 �ɏ������񂾒l�𓐂݌��āA�������Ă������W�X�^�ł� (X68030�ł͖���)
                    ; Area Set ���W�X�^�� Write Only �Ȃ̂ŉ������������킩��Ȃ��̂ł����A������ǂނ��Ƃ�
                    ; 0 �Ԓn���� ((���̒l+1)�~8192-1) �Ԓn�܂ł̃A�h���X�� Human68k �� SUPERVISOR �̈�ƂȂ��Ă��邱�Ƃ��킩��܂�