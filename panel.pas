
program panel;
{fpc panel.pas -k-lX11}
uses
  xlib, xutil, x, ctypes, unixtype, baseunix, sysutils;

const
  WIN_W = 800;
  WIN_H = 600;
  CELLS_PER_ROW = 4;
  CELLS_PER_COL = 4;
  CELL_SIZE = 50;
  GAP = 10;

var
  dpy: PDisplay;
  win: TWindow;
  scr: cint;
  gc: TGC;
  e: TXEvent;
  states: array[0..CELLS_PER_ROW*CELLS_PER_COL-1] of cint;

procedure DrawGrid;
var
  r,c,idx,x1,y1: cint;
  grid_w, grid_h, start_x, start_y: cint;
begin
  grid_w := CELLS_PER_ROW * CELL_SIZE + (CELLS_PER_ROW - 1) * GAP;
  grid_h := CELLS_PER_COL * CELL_SIZE + (CELLS_PER_COL - 1) * GAP;
  start_x := (WIN_W - grid_w) div 2;
  start_y := (WIN_H - grid_h) div 2;

  // fundo amarelo
  XSetForeground(dpy, gc, $FFFF00); // RGB amarelo
  XFillRectangle(dpy, win, gc, 0, 0, WIN_W, WIN_H);

  for r := 0 to CELLS_PER_COL-1 do
    for c := 0 to CELLS_PER_ROW-1 do
      begin
        idx := r*CELLS_PER_ROW+c;
        x1 := start_x + c*(CELL_SIZE+GAP);
        y1 := start_y + r*(CELL_SIZE+GAP);

        if states[idx] = 1 then
          XSetForeground(dpy, gc, $000000)  // preto
        else
          XSetForeground(dpy, gc, $FFFFFF); // branco

        XFillRectangle(dpy, win, gc, x1, y1, CELL_SIZE, CELL_SIZE);

        // contorno preto
        XSetForeground(dpy, gc, $000000);
        XDrawRectangle(dpy, win, gc, x1, y1, CELL_SIZE, CELL_SIZE);
      end;
  XFlush(dpy);
end;

function HitCell(mx,my: cint): cint;
var
  grid_w, grid_h, start_x, start_y: cint;
  col,row,cell_x,cell_y: cint;
begin
  grid_w := CELLS_PER_ROW * CELL_SIZE + (CELLS_PER_ROW - 1) * GAP;
  grid_h := CELLS_PER_COL * CELL_SIZE + (CELLS_PER_COL - 1) * GAP;
  start_x := (WIN_W - grid_w) div 2;
  start_y := (WIN_H - grid_h) div 2;

  if (mx < start_x) or (mx >= start_x+grid_w) or
     (my < start_y) or (my >= start_y+grid_h) then
  begin
    HitCell := -1;
    exit;
  end;

  col := (mx - start_x) div (CELL_SIZE+GAP);
  row := (my - start_y) div (CELL_SIZE+GAP);

  cell_x := start_x + col*(CELL_SIZE+GAP);
  cell_y := start_y + row*(CELL_SIZE+GAP);

  if (mx >= cell_x) and (mx < cell_x+CELL_SIZE) and
     (my >= cell_y) and (my < cell_y+CELL_SIZE) then
    HitCell := row*CELLS_PER_ROW+col
  else
    HitCell := -1;
end;

var
  idx: cint;
  cmd: string;
begin
  FillChar(states, SizeOf(states), 0);

  dpy := XOpenDisplay(nil);
  if dpy = nil then Halt(1);
  scr := DefaultScreen(dpy);

  win := XCreateSimpleWindow(dpy, RootWindow(dpy, scr),
    10, 10, WIN_W, WIN_H, 1,
    BlackPixel(dpy,scr), WhitePixel(dpy,scr));

  XSelectInput(dpy, win, ExposureMask or ButtonPressMask or KeyPressMask);
  XMapWindow(dpy, win);

  gc := XCreateGC(dpy, win, 0, nil);

  while True do
  begin
    XNextEvent(dpy, @e);
    case e._type of
      Expose:
        DrawGrid;
      ButtonPress:
        begin
          idx := HitCell(e.xbutton.x, e.xbutton.y);
          if idx >= 0 then
          begin
            states[idx] := 1 - states[idx];
            DrawGrid;

            
            cmd := 'echo command' + IntToStr(idx+1) + ' ' + IntToStr(states[idx]);
            ExecuteProcess('/bin/sh', ['-c', cmd]);
          end;
        end;
      KeyPress:
        Halt(0);
    end;
  end;

  XCloseDisplay(dpy);
end.
