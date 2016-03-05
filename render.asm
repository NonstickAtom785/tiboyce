palette_colors:
	.dw $0421 * 31 + $8000
	.dw $0421 * 21 + $8000
	.dw $0421 * 10
	.dw $0421 * 0

update_palettes:
	ld hl,(hram_base+BGP)
curr_palettes = $+1
	ld de,$FFFFFF
	or a
	sbc hl,de
	ret z
	add hl,de
	ld (curr_palettes),hl
	ld de,mpLcdPalette + (12*2)-1
	push bc
	 push ix
	  ld bc,12*2
	  ld ix,palette_colors+1
update_palettes_loop:
	  xor a
	  add hl,hl
	  adc a,a
	  add hl,hl
	  adc a,a
	  add a,a
	  ld (_+2),a
	  push hl
_
	   lea hl,ix
	   ldd
	   ldd
	  pop hl
	  jp pe,update_palettes_loop
	 pop ix
	pop bc
	ret
	
cursorcode:
	.org cursormem
draw_sprites_done:
draw_sprites_save_sp = $+1
	ld sp,0
	ret
	
draw_sprites:
	ld a,(hram_base+LCDC)
	bit 1,a
	ret z
	ld (draw_sprites_save_sp),sp
	ld ix,hram_base+$FEA0
draw_next_sprite:
	ld a,ixl
	or a
	jr z,draw_sprites_done
	lea ix,ix-4
	ld a,(ix)
	dec a
	cp 159
	jr nc,draw_next_sprite
	ld e,a
	ld a,(ix+1)
	ld b,a
	dec a
	cp 167
	jr nc,draw_next_sprite
	
	ld iy,scanlineLUT
	ld d,3
	mlt de
	add iy,de
	
	ld e,(ix+2)
	ld d,64
	mlt de
	ld hl,vram_pixels_start
	add hl,de
	ex de,hl
	
	ld hl,(current_buffer)
	
	bit 5,(ix+3)
	jr nz,draw_sprite_hflip
	sub 7
	jr c,_
	ld b,8
	ld l,a
	add a,256-152
	jr nc,draw_sprite_no_hflip_done
	cpl
	adc a,b
	ld b,a
	jr draw_sprite_no_hflip_done
_
	ld a,e
	add a,8
	sub b
	ld e,a
	jr draw_sprite_no_hflip_done
	
draw_sprite_hflip:
	ld l,a
	cp 7
	jr c,draw_sprite_hflip_done
	ld b,8
	sub 159
	jr c,draw_sprite_hflip_done
	ld l,159
	ld b,a
	add a,e
	ld e,a
	ld a,8
	sub b
	ld b,a
draw_sprite_hflip_done:
	ld a,$2B	;DEC HL
	jr _
draw_sprite_no_hflip_done:
	ld a,$23	;INC HL
_
	ld (draw_sprite_normal_hdir),a
	ld (draw_sprite_priority_hdir),a
	
	ld sp,hl
	
	ld a,(hram_base+LCDC)
	bit 2,a
	ld c,8
	jr z,_
	res 6,e
	ld c,16
_
	
	ld a,3
	bit 6,(ix+3)
	jr z,_
	ld a,-3
	lea iy,iy+(7*3)
	bit 4,c
	jr z,_
	lea iy,iy+(8*3)
_
	ld (draw_sprite_normal_vdir),a
	ld (draw_sprite_priority_vdir),a
	
	bit 4,(ix+3)
	ld a,$44
	jr z,_
	add a,a
_
	bit 7,(ix+3)
	jr nz,draw_sprite_priority
	
draw_sprite_normal:
	ld (draw_sprite_normal_palette),a
	ld a,e
draw_sprite_normal_row:
	ld hl,(iy)
	add hl,sp
draw_sprite_normal_vdir = $+2
	lea iy,iy+3
	jr c,draw_sprite_normal_vclip
	push.s bc
draw_sprite_normal_pixels:
	 ld a,(de)
	 or a
	 jr z,_
draw_sprite_normal_palette = $+1
	 add a,$44
	 ld (hl),a
_
	 inc de
draw_sprite_normal_hdir:
	 inc hl
	 djnz draw_sprite_normal_pixels
	pop.s bc
	ld a,e
	sub b
draw_sprite_normal_vclip:
	add a,8
	ld e,a
	dec c
	jr nz,draw_sprite_normal_row
	jp draw_next_sprite
	
draw_sprite_priority:
	ld (draw_sprite_priority_palette),a
	ld a,e
draw_sprite_priority_row:
	ld hl,(iy)
	add hl,sp
draw_sprite_priority_vdir = $+2
	lea iy,iy+3
	jr c,draw_sprite_priority_vclip
	push.s bc
draw_sprite_priority_pixels:
	 ld a,(hl)
	 or a
	 jr nz,_
	 ld a,(de)
	 or a
	 jr z,_
draw_sprite_priority_palette = $+1
	 add a,$44
	 ld (hl),a
_
	 inc de
draw_sprite_priority_hdir:
	 inc hl
	 djnz draw_sprite_priority_pixels
	pop.s bc
	ld a,e
	sub b
draw_sprite_priority_vclip:
	add a,8
	ld e,a
	dec c
	jr nz,draw_sprite_priority_row
	jp draw_next_sprite
	
write_vram_and_expand:
	push bc
	 push de
	  push hl
	   ld c,a
	   ex af,af'
	   xor a
	   ld (mpTimerCtrl),a
	   ld hl,vram_base
	   lea de,ix
	   add hl,de
	   ld (hl),c
	   ld a,d
	   sub $98
	   jr c,write_vram_pixels
	   ld h,a
	   ld a,e
	   and $E0
	   ld l,a
	   xor e
	   add a,a
	   ld e,a
	   ld a,c
	   add hl,hl
	   add hl,hl
	   add.s hl,hl
	   ld bc,vram_tiles_start
	   add hl,bc
	   ld d,0
	   add hl,de
	   ld e,64
	   ld c,a
	   ld b,e
	   mlt bc
	   ld (hl),c
	   inc hl
	   ld (hl),b
	   add hl,de
	   ld (hl),b
	   dec hl
	   ld (hl),c
	   add hl,de
	   add a,a
	   jr c,_
	   set 6,b
_
	   ld (hl),c
	   inc hl
	   ld (hl),b
	   add hl,de
	   ld (hl),b
	   dec hl
	   ld (hl),c
	  pop hl
	 pop de
	pop bc
	ld a,TMR_ENABLE
	ld (mpTimerCtrl),a
	ex af,af'
	ret.l
write_vram_pixels:
	   res 0,l
	   ld hl,(hl)
	   ex de,hl
	   res 0,l
	   add hl,hl
	   add hl,hl
	   ld bc,vram_pixels_start-($8000*4)
	   add hl,bc
	   ld b,0
	   ld a,17
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c \ inc hl
	   sla d \ rl b \ sla e \ rl b \ ld c,a \ mlt bc \ ld (hl),c
	  pop hl
	 pop de
	pop bc
	ld a,TMR_ENABLE
	ld (mpTimerCtrl),a
	ex af,af'
	ret.l
	
render_scanline:
	push ix
	 ld.sis (render_save_sps),sp
	 ld (render_save_spl),sp
	 ld a,vram_tiles_start >> 16
	 ld mb,a
	 ld ix,hram_base+ioregs
	 ld a,(ix-ioregs+LY)
	 add a,(ix-ioregs+SCY)
	 rrca
	 rrca
	 rrca
	 ld e,a
	 and $1F
	 ld d,a
	 xor e
	 rrca
	 rrca
	 ld hl,vram_pixels_start
	 ld l,a
	 push hl
	  ld a,(ix-ioregs+SCX)
	  ld c,a
	  rrca
	  rrca
	  and $3E
	  ld e,a
	  
	  ld a,c
	  cpl
	  and 7
	  ld c,a
	  
	  ld a,(ix-ioregs+LCDC)
	  bit 4,a
	  jr nz,_
	  set 7,e
_
	  bit 3,a
	  jr z,_
	  set 5,d
_
	  ld hl,vram_tiles_start
	  add hl,de
	  ld.s sp,hl
	 pop hl
	 
	 ld b,167
	 
	 bit 5,a
	 jr z,scanline_no_window
	 
	 ld a,(ix-ioregs+LY)
	 cp (ix-ioregs+WY)
	 jr c,scanline_no_window
	 
	 ld a,(ix-ioregs+WX)
	 cp b
	 jr nc,scanline_no_window
	 
	 ld b,a
	 call scanline_do_render
	 
window_tile_ptr = $+1
	 ld hl,vram_tiles_start
	 ld a,(hram_base+LCDC)
	 bit 4,a
	 jr nz,_
	 ld l,$80
_
	 bit 6,a
	 jr z,_
	 ld a,h
	 add a,$20
	 ld h,a
_
	 ld.sis sp,hl
	 
window_tile_offset = $+1
	 ld hl,vram_pixels_start
	 ld a,l
	 add a,8
	 cp 64
	 jr c,_
	 ld a,(window_tile_ptr+1)
	 inc a
	 ld (window_tile_ptr+1),a
	 xor a
_
	 ld (window_tile_offset),a
	 
	 ld b,167
	 ld a,(hram_base+WX)
	 ld c,a
	 
scanline_no_window:
	 call scanline_do_render
	 
	 ld hl,(scanline_ptr)
	 ld c,3
	 add hl,bc
	 ld (scanline_ptr),hl
	 ld a,z80codebase >> 16
	 ld mb,a
	 ld.sis sp,(render_save_sps)
	pop ix
	ret.l
	 
	; Input: C=Start X+7, B=End X+7, HL=pixel base pointer, SPS=tilemap pointer
scanline_do_render:
	ld a,c
	sub b
	ret nc
	
	ld (render_save_spl),sp
	ld sp,hl
	add a,167
	and $F8
	ld e,a
	ld d,6*32
	mlt de
	ld b,e
	ld e,d
	ld d,b
	ld ix,scanline_unrolled
	add ix,de
	
scanline_ptr = $+1
	ld hl,(scanlineLUT+(15*3))
current_buffer = $+1
	ld de,gb_frame_buffer_1
	add hl,de
	ex de,hl
	ld a,c
	sub 7
	jr nc,no_clip
	
	cpl
	pop.s hl
	adc a,l
	ld l,a
	add hl,sp
	inc c
	ldir
	ld a,8
	jp (ix)
	 
no_clip:
	ld c,a
	ex de,hl
	add hl,bc
	ex de,hl
	ld a,8
	jp (ix)
	
scanline_unrolled:
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	pop.s hl \ add hl,sp \ ld c,a \ ldir
	
render_save_spl = $+1
	ld sp,0
	ret
cursorcodesize = $-cursormem
	.org cursorcode+cursorcodesize
	
	.echo "Cursor memory code size: ", cursorcodesize