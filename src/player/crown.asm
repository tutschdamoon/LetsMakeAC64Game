CROWN: {
	*=* "CROWN"
	PlayerHasCrown:
			.byte $00

	Crown_X:
			.byte $00, $6a, $00
	Crown_Y:
			.byte $31
	CrownFallIndex:
			.byte $00

	Initialise: {
			// lda #$46
			// sta SPRITE_POINTERS + 5	
			rts
	}

	DrawCrown: {
		/*
		 hayesmaker64: because it would be quite funny 
		 if the crown fell off when you opened your mouth 
		 to eat... making it possible for the other player
		 to grab it.. and take an advantage somehow
		 */
		 	//Enable crown if it is active
			//Crown sprite
			lda PlayerHasCrown	
			bmi !NoCrown+
		!Crown:
			lda $d015
			ora #%00100000
			sta $d015
			lda PlayerHasCrown
			bne !+
			lda #$5e
			jmp !ApplyCrown+
		!:
			tay
			dey
			lda PLAYER.Player1_State, y
			and #[PLAYER.STATE_FACE_LEFT]
			bne !FaceLeft+
		!FaceRight:
			lda #$47
			jmp !ApplyCrown+
		!FaceLeft:
			lda #$46
		!ApplyCrown:
			sta SPRITE_POINTERS + 5
		!NotOnPlayer:
			

			//Now attach crown to player
			lda PlayerHasCrown   //0, 1 or 2
			asl
			tax
			lda CrownPosTableX + 0, x
			sta CROWN_POS_X + 0
			lda CrownPosTableX + 1, x
			sta CROWN_POS_X + 1
			lda CrownPosTableY + 0, x
			sta CROWN_POS_Y + 0
			lda CrownPosTableY + 1, x
			sta CROWN_POS_Y + 1

			// .break
			ldy #$00
			lda (CROWN_POS_Y), y //lsb
			sta VIC.SPRITE_5_Y

			iny
			lda (CROWN_POS_X), y //lsb
			sta VIC.SPRITE_5_X

			lda $d010
			and #%11011111
			tax
			iny
			lda (CROWN_POS_X), y //msb
			beq !noMsb+
			txa
			ora #%00100000
			tax
		!noMsb:
			txa
			sta $d010

			//Only fall if player doesnt have crown
			lda PlayerHasCrown
			bne !+
			jsr Fall
			jsr PickUp
		!:

			rts



		!NoCrown:
			lda $d015
			and #%11011111
			sta $d015
			rts

		CrownPosTableX:
			.word Crown_X
			.word PLAYER.Player1_X
			.word PLAYER.Player2_X
		CrownPosTableY:
			.word Crown_Y
			.word PLAYER.Player1_Y
			.word PLAYER.Player2_Y
	}


	Fall: {
			lda #<Crown_X
			sta COLLISION_POINT_X + 0
			lda #>Crown_X
			sta COLLISION_POINT_X + 1
			lda #<Crown_Y
			sta COLLISION_POINT_Y + 0
			lda #>Crown_Y
			sta COLLISION_POINT_Y + 1


			lda #$0e
			sta COLLISION_POINT_X_OFFSET
			lda #$07
			sta COLLISION_POINT_Y_OFFSET
			jsr UTILS.GetCollisionPoint

			jsr UTILS.GetCharacterAt
			tax
			lda CHAR_COLORS, x
			and #UTILS.COLLISION_SOLID
			beq !Fall+
		!NotFall:
			lda #[TABLES.__JumpAndFallTable - TABLES.JumpAndFallTable - 1]
			sta CrownFallIndex
			lda Crown_Y
			and #$f8
			ora #$03
			sta Crown_Y

			jmp !FallComplete+
		!Fall:
			ldx CrownFallIndex
			lda Crown_Y
			clc 
			adc TABLES.JumpAndFallTable, x
			sta Crown_Y
			dex 
			bpl !+
			inx
		!:
			stx CrownFallIndex
		!FallComplete:

			rts
	}

	PickUp: {
			.label Sprite1_X = COLLISION_POINT_X
			.label Sprite1_Y = COLLISION_POINT_Y
			.label Sprite2_X = COLLISION_POINT_X1
			.label Sprite2_Y = COLLISION_POINT_Y1

			.label Sprite1_W = COLLISION_WIDTH
			.label Sprite2_W = COLLISION_WIDTH1
			.label Sprite1_H = COLLISION_HEIGHT
			.label Sprite2_H = COLLISION_HEIGHT1

			.label Sprite1_XOFF = COLLISION_POINT_X_OFFSET
			.label Sprite2_XOFF = COLLISION_POINT_X1_OFFSET
			.label Sprite1_YOFF = COLLISION_POINT_Y_OFFSET
			.label Sprite2_YOFF = COLLISION_POINT_Y1_OFFSET


			//Define crown dimenisons
			lda #<Crown_X
			ldx #>Crown_X
			sta Sprite2_X + 0
			stx Sprite2_X + 1 

			lda #<Crown_Y
			ldx #>Crown_Y
			sta Sprite2_Y + 0
			stx Sprite2_Y + 1 

			lda #$05
			sta Sprite2_XOFF
			lda #$0c
			sta Sprite2_W

			lda #$00
			sta Sprite2_YOFF
			lda #$07 
			sta Sprite2_H



			//Player 1
			lda PLAYER.Player1_State
			and #[PLAYER.STATE_EATING]
			bne !+

			lda #<PLAYER.Player1_X
			ldx #>PLAYER.Player1_X
			sta Sprite1_X + 0
			stx Sprite1_X + 1

			lda #<PLAYER.Player1_Y
			ldx #>PLAYER.Player1_Y
			sta Sprite1_Y + 0
			stx Sprite1_Y + 1

			lda #$04
			sta Sprite1_XOFF
			lda #$10
			sta Sprite1_W	
			lda #$15
			sta Sprite1_H
			jsr UTILS.GetSpriteCollision
			bcc !+
			lda #$01
			sta PlayerHasCrown
			jmp !Exit+
		!:


			//Player 2
			lda PLAYER.Player2_State
			and #[PLAYER.STATE_EATING]
			bne !+

			lda #<PLAYER.Player2_X
			ldx #>PLAYER.Player2_X
			sta Sprite1_X + 0
			stx Sprite1_X + 1

			lda #<PLAYER.Player2_Y
			ldx #>PLAYER.Player2_Y
			sta Sprite1_Y + 0
			stx Sprite1_Y + 1

			lda #$04
			sta Sprite1_XOFF
			lda #$10
			sta Sprite1_W
			lda #$06
			sta Sprite1_YOFF				
			lda #$15
			sta Sprite1_H
			jsr UTILS.GetSpriteCollision
			bcc !+
			lda #$02
			sta PlayerHasCrown
			jmp !Exit+
		!:

		!Exit:
			rts
	}
}