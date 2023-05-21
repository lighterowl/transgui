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

uses vargrid, varlist, fgl, classes;

type TIntegerList = specialize TFPGList<Integer>;

procedure CollectFilters(FilterVG: TVarGrid;
  var StateFilters: TIntegerList;
  var PathFilters, TrackerFilters, LabelFilters: TStringList
);

function MatchStateFilter(Filters: TIntegerList; Torrents: TVarList;
TorrentRow: Integer; RPCVer: Integer; IsActive: Boolean): Boolean;

function MatchTrackerFilter(Trackers: TStringList; Torrents: TVarList;
TorrentRow: Integer): Boolean;

function MatchLabelFilter(Labels: TStringList; Torrents: TVarList;
TorrentRow: Integer): Boolean;

function MatchPathFilter(Paths: TStringList; Torrents: TVarList;
TorrentRow: Integer): Boolean;

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

uses TorrentColumns, TorrentStateImages, RPCConstants, Variants, StrUtils;

function MatchSingleStateFilter(Filter: Integer; Torrents: TVarList;
  TorrentRow: Integer; RPCVer: Integer; IsActive: Boolean): Boolean;
var
  status, StateImg: Integer;
begin
  Result := False;
  status := Torrents[torcolStatus, TorrentRow];
  StateImg := Torrents[torcolStateImg, TorrentRow];
  case Filter of
    frowAll: Result := True;
    frowActive: Result := IsActive;
    frowInactive: Result := (IsActive=False) and ((StateImg in [imgStopped, imgDone])=False);
    frowDown: Result := (status = TR_STATUS_DOWNLOAD(RPCVer));
    frowDone: Result := (StateImg = imgDone) or (status = TR_STATUS_SEED(RPCVer));
    frowStopped: Result := (StateImg in [imgStopped, imgDone]);
    frowError: Result := (StateImg in [imgDownError, imgSeedError, imgError]);
    frowWaiting:
      Result := (status in [TR_STATUS_CHECK(RPCVer), TR_STATUS_CHECK_WAIT(RPCVer), TR_STATUS_DOWNLOAD_WAIT(RPCVer)]);
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
  StateFilters := TIntegerList.Create;

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

type VariantStringMatcher = function (value: variant; filter: string): Boolean;

function MatchTracker(value: variant; filter: string): Boolean;
begin
  Result := (value = filter);
end;

function MatchLabel(value: variant; filter: string): Boolean;
begin
  Result := StrUtils.AnsiContainsStr(String(value), filter);
end;

function MatchPath(value: variant; filter: string): Boolean;
begin
  Result := (System.UTF8Decode(filter) = value);
end;

function MatchStringList(Wanted: TStringList; Torrents: TVarList;
Row: Integer; Column: Integer; Match: VariantStringMatcher): Boolean;
var
  v: variant;
  s: string;
begin
  if Wanted.Count = 0 then
    exit(True);

  v := Torrents[Column, Row];
  if VarIsEmpty(v) then
    exit(True);

  for s in Wanted do
  begin
    if Match(v, s) then
      exit(True);
  end;

  Result := False;
end;

function MatchStateFilter(Filters: TIntegerList; Torrents: TVarList;
TorrentRow: Integer; RPCVer: Integer; IsActive: Boolean): Boolean;
var
  f: Integer;
begin
  if Filters.Count = 0 then
    exit(True);

  for f in Filters do
  begin
    if MatchSingleStateFilter(f, Torrents, TorrentRow, RPCVer, IsActive) then
      exit(True);
  end;
  Result := False;
end;

function MatchTrackerFilter(Trackers: TStringList; Torrents: TVarList;
TorrentRow: Integer): Boolean;
begin
  Result := MatchStringList(Trackers, Torrents, TorrentRow, torcolTracker,
    @MatchTracker);
end;

function MatchLabelFilter(Labels: TStringList; Torrents: TVarList;
TorrentRow: Integer): Boolean;
begin
  Result := MatchStringList(Labels, Torrents, TorrentRow, torcolLabels,
    @MatchLabel);
end;

function MatchPathFilter(Paths: TStringList; Torrents: TVarList;
TorrentRow: Integer): Boolean;
begin
  Result := MatchStringList(Paths, Torrents, TorrentRow, torcolPath,
    @MatchPath);
end;

end.
