{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2019 by Yury Sidorov and Transmission Remote GUI working group.
  Copyright (c) 2023 Daniel Kamil Kozar

  Transmission Remote GUI is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Transmission Remote GUI is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  In addition, as a special exception, the copyright holders give permission to
  link the code of portions of this program with the
  OpenSSL library under certain conditions as described in each individual
  source file, and distribute linked combinations including the two.

  You must obey the GNU General Public License in all respects for all of the
  code used other than OpenSSL.  If you modify file(s) with this exception, you
  may extend this exception to your version of the file(s), but you are not
  obligated to do so.  If you do not wish to do so, delete this exception
  statement from your version.  If you delete this exception statement from all
  source files in the program, then also delete it here.
*************************************************************************************}

unit TrackerUri;

{$mode ObjFPC}{$H+}{$J-}

interface

uses SysUtils;

function Filter(s : string) : string;

implementation

function Filter(s : string) : string;
var
  host_start, host_end: integer;
  subdom_end: integer;
  subdom: shortstring;
begin
  host_start := Pos('://', s);
  if host_start > 0 then host_start := host_start + 3
  else                   host_start := 1;

  host_end := Pos(':', s, host_start);
  if host_end > 0 then begin
    host_end := host_end - 1;
  end
  else begin
    host_end := Pos('/', s, host_start);
    if host_end > 0 then host_end := host_end - 1
    else                 host_end := Length(s);
  end;

  subdom_end := Pos('.', s, host_start);
  if subdom_end > 0 then begin
    subdom:=LowerCase(Copy(s, host_start, subdom_end - host_start));
    if (subdom = 'bt') or (subdom = 'www') or (subdom = 'tracker') then
      host_start := subdom_end + 1
    else
      if (Length(subdom) = 3) and (subdom[1] = 'b') and (subdom[2] = 't') and (subdom[3] in ['0'..'9']) then
        host_start := subdom_end + 1;
  end;

  Result := Copy(s, host_start, host_end - host_start + 1);
end;

end.

