.db "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

.org $8000

.define Scroll_X                            $00                 ; For BackGround 
.define Buttons                             $01
.define Background_Table                    $02
.define Printing_Value                      $03
.define Value_On_Y                          $04                 ; For Sprite move
.define Value_On_X                          $05                 ; For Sprite move

.define PPUCTRL                             $2000
.define PPUMASK                             $2001
.define OAMADDR                             $2003
.define OAMDATA                             $2004
.define PPUSCROLL                           $2005
.define PPUADDR                             $2006
.define PPUDATA                             $2007

.define OAMDMA                              $4014
.define JOYPAD1                             $4016
.define JOYPAD2                             $4017

.define NameTable_Position_Offset           #$A8

start:

    ; PPU Register Settings ----------------------------------------
    LDA #%10010000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK
    ; --------------------------------------------------------------

    ; Palette Background -------------------------------------------
    LDA #$3f
    STA PPUADDR
    LDA #0
    STA PPUADDR
    
    LDA #$19
    STA PPUDATA
    LDA #$05
    STA PPUDATA
    LDA #$28
    STA PPUDATA
    LDA #$0F
    STA PPUDATA
    ; ----------------------------------------------------------------

    ; Palette Sprites -----------------------------------------------
    LDA #$3f
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    LDA #$21
    STA PPUDATA
    LDA #$17
    STA PPUDATA
    LDA #$18
    STA PPUDATA
    LDA #$14
    STA PPUDATA
    ; ----------------------------------------------------------------------

    ; Print Background Loop ------------------------------------------------
    Print_Nametable_0:                           ; Printing Nametable 0
    LDA #$20
    STA PPUADDR
    LDA NameTable_Position_Offset
    STA PPUADDR
    JSR Printing_Backgorund_Loop
    
    Print_Nametable_1:                           ; Printing Nametable 1
    LDA #0                                       ; Resetting values
    STA Background_Table
    LDA #$24
    STA PPUADDR
    LDA NameTable_Position_Offset
    STA PPUADDR
    JSR Printing_Backgorund_Loop
    JMP Exit_Loop

    ;Core Loop -----------------------------------------------------------------------
        Printing_Backgorund_Loop:
        LDA Background_Table                    ; Take pattern table index
        STA PPUDATA
        INC Background_Table                    ; Increment Pattern Table Index
        LDA Background_Table
        AND #$0F                                ; Chech if reach the last line value  
        BEQ Reset_Offset
        DEC Printing_Value
        BNE Printing_Backgorund_Loop
        RTS
        
        Reset_Offset:                           ; Print for #16 times "white" pixels
        LDY #16                                 ; so we can fill the remaining pixels
        lOOPWHITE:                              ; on Name Table
        LDA #00
        STA PPUDATA
        DEY 
        BNE lOOPWHITE
        JMP Printing_Backgorund_Loop
    ;------------------------------------------------------------------------------

    ;Exit Loop---------------------------------------------------------------------
        Exit_Loop:                              ; When the background loop is end  
        LDA #$69                                ; we'll print the sprite
        STA Value_On_Y
        STA OAMDATA
        LDA #$FE                                ; Choose the sprite
        STA OAMDATA
        LDA #%10000000
        STA OAMDATA
        LDA #$79
        STA Value_On_X                          ; Store pos x/y in an address  
        STA OAMDATA
    ;-------------------------------------------------------------------------------

    ;-------------------------------------------------------------------------------
    
    
loop:
    JMP loop

readjoy:
    LDA #$01
    STA JOYPAD1
    STA Buttons
    LSR A
    STA JOYPAD1
joyloop:
    LDA JOYPAD1
    LSR A 
    ROL Buttons
    BCC joyloop
    RTS

nmi:
    PHA
    JSR readjoy
    PLA
    
    ;Controlls----------------------------------------------
    Right:
    LDA Buttons                         ; Check input
    AND #%00000001
    BEQ Left
    LDA Value_On_X                      ; Check screen limit
    CMP #$F7
    BEQ ELSE
    INC Scroll_X
    INC Value_On_X
    LDA #03
    STA OAMADDR
    LDA Value_On_X
    STA OAMDATA

    Left:   
    LDA Buttons                         ; Check input
    AND #%00000010
    BEQ Up
    LDA Value_On_X                      ; Check screen limit
    CMP #$01
    BEQ ELSE
    DEC Scroll_X
    DEC Value_On_X
    LDA #03
    STA OAMADDR
    LDA Value_On_X
    STA OAMDATA
    
    Up:
    LDA Buttons                         ; Check input
    AND #%00001000
    BEQ Down
    LDA Value_On_Y                      ; Check screen limit
    CMP #$09
    BEQ ELSE
    DEC Value_On_Y
    LDA #0
    STA OAMADDR
    LDA Value_On_Y
    STA OAMDATA
    
    Down:
    LDA Buttons                         ; Check input
    AND #%00000100
    BEQ loadscroll
    LDA Value_On_Y                      ; Check screen limit
    CMP #$E0
    BEQ ELSE
    INC Value_On_Y
    LDA #0
    STA OAMADDR
    LDA Value_On_Y
    STA OAMDATA
    ;------------------------------------------------------------------------

loadscroll:
    LDA Scroll_X
    STA PPUSCROLL
    LDA #0
    STA PPUSCROLL
    RTI

ELSE:
NOP

irq:
    RTI

.goto $FFFA

.dw nmi
.dw start
.dw irq

.incbin mario0.chr
.incbin aiv256.chr