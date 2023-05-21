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
{$modeswitch nestedprocvars}

interface

uses vargrid, fgl, classes;

type TIntegerList = specialize TFPGList<Integer>;

procedure CollectFilters(FilterVG: TVarGrid;
  var StateFilters: TIntegerList;
  var PathFilters, TrackerFilters, LabelFilters: TStringList
);

type TFilterType = (ftPath, ftLabel, ftTracker);

const

// always-available rows in lvFilter.Items
frowAll      = 0;
frowDown     = 1;
frowDone     = 2;
frowActive   = 3;
frowInactive = 4;
frowStopped  = 5;
frowError    = 6;
frowWaiting  = 7;

StatusFiltersCount = frowWaiting + 1;

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

function MatchSingleStateFilter(Filter: Integer; Torrents: TVarList;
  TorrentRow: Integer; RPCVer: Integer; IsActive: Boolean): Boolean;
var
  status, StateImg: Integer;
begin
  status := Torrents[idxStatus, TorrentRow];
  StateImg := Torrents[torcolStateImg, TorrentRow];
  case Filter of
    frowActive:
      if not IsActive then
        continue;
    frowInactive:
      if (IsActive=true) or ((StateImg in [imgStopped, imgDone])=true) then // PETROV
        continue;
    frowDown:
      if status <> TR_STATUS_DOWNLOAD(RPCVer) then
        continue;
    frowDone:
      if (StateImg <> imgDone) and (status <> TR_STATUS_SEED(RPCVer)) then
        continue;
    frowStopped:
      if not (StateImg in [imgStopped, imgDone]) then
        continue;
    frowError:
      if not (StateImg in [imgDownError, imgSeedError, imgError]) then
        continue;
    frowWaiting:
        if (status <> TR_STATUS_CHECK(RPCVer)) and (status <> TR_STATUS_CHECK_WAIT(RPCVer)) and (status <> TR_STATUS_DOWNLOAD_WAIT(RPCVer))then
          continue;
  end;
end;

procedure CollectFilters(FilterVG: TVarGrid;
  var StateFilters: TIntegerList;
  var PathFilters, TrackerFilters, LabelFilters: TStringList
);
procedure FilterRowCbk(Sender: TVarGrid; Row: Integer);
begin
  if Row < StatusFiltersCount then begin
    StateFilters.Add(Row);
  end
  else
    case TFilterType(Sender.Items[fcolFilterType, Row]) of
      ftPath:    PathFilters.Add(Sender.Items[fcolRawData, Row]);
      ftLabel:   LabelFilters.Add(Sender.Items[fcolRawData, Row]);
      ftTracker: TrackerFilters.Add(Sender.Items[fcolRawData, Row]);
    end;
end;
begin
  StateFilters   := TIntegerList.Create;

  PathFilters := TStringList.Create;
  PathFilters.Sorted := True;
  PathFilters.Duplicates := dupIgnore;

  TrackerFilters := TStringList.Create;
  TrackerFilters.Sorted := True;
  TrackerFilters.Duplicates := dupIgnore;

  LabelFilters := TStringList.Create;
  LabelFilters.Sorted := True;
  LabelFilters.Duplicates := dupIgnore;

  FilterVG.ForEachSelectedRow(@FilterRowCbk);
end;

end.

