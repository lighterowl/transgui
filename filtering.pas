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

unit Filtering;

{$mode ObjFPC}

interface

type TFilterType = (ftPath, ftLabel, ftTracker);

const

// always-available rows in lvFilter.Items
fltAll      = 0;
fltDown     = 1;
fltDone     = 2;
fltActive   = 3;
fltInactive = 4;
fltStopped  = 5;
fltError    = 6;
fltWaiting  = 7;

StatusFiltersCount = fltWaiting + 1;

// definitions of column indices in lvFilter.Items
{ the thing displayed in the table. the number of matching torrents in the
  given group in parentheses is appended on each update }
fcolDisplayText = 0;

{ the raw string to be used for matching torrents, i.e. without the count }
fcolRawData = -1;

{ a TFilterType value instructing code on what to filter on }
fcolFilterType = -2;

lvFilterNumExtraColumns = 2;

implementation

uses
  Classes, SysUtils;

end.

