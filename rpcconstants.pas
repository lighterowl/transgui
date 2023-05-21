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

unit RPCConstants;

{$mode ObjFPC}

interface

function TR_STATUS_STOPPED(RPCVer: Integer): Integer;
function TR_STATUS_CHECK_WAIT(RPCVer: Integer): Integer;
function TR_STATUS_CHECK(RPCVer: Integer): Integer;
function TR_STATUS_DOWNLOAD_WAIT(RPCVer: Integer): Integer;
function TR_STATUS_DOWNLOAD(RPCVer: Integer): Integer;
function TR_STATUS_SEED_WAIT(RPCVer: Integer): Integer;
function TR_STATUS_SEED(RPCVer: Integer): Integer;

implementation

const

TR_STATUS_CHECK_WAIT_OLD = ( 1 shl 0 ); // Waiting in queue to check files
TR_STATUS_CHECK_OLD      = ( 1 shl 1 ); // Checking files
TR_STATUS_DOWNLOAD_OLD   = ( 1 shl 2 ); // Downloading
TR_STATUS_SEED_OLD       = ( 1 shl 3 ); // Seeding
TR_STATUS_STOPPED_OLD    = ( 1 shl 4 ); // Torrent is stopped

TR_STATUS_STOPPED_NEW       = 0;     // Torrent is stopped
TR_STATUS_CHECK_WAIT_NEW    = 1;     // Queued to check files
TR_STATUS_CHECK_NEW         = 2;     // Checking files
TR_STATUS_DOWNLOAD_WAIT_NEW = 3;     // Queued to download
TR_STATUS_DOWNLOAD_NEW      = 4;     // Downloading
TR_STATUS_SEED_WAIT_NEW     = 5;     // Queued to seed
TR_STATUS_SEED_NEW          = 6;     // Seeding

function Status(RPCVer, OldStatus, NewStatus: Integer): Integer;
begin
  if RPCVer < 14 then Result := OldStatus else Result := NewStatus;
end;

function TR_STATUS_STOPPED(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, TR_STATUS_STOPPED_OLD, TR_STATUS_STOPPED_NEW);
end;

function TR_STATUS_CHECK_WAIT(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, TR_STATUS_CHECK_WAIT_OLD, TR_STATUS_CHECK_WAIT_NEW);
end;

function TR_STATUS_CHECK(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, TR_STATUS_CHECK_OLD, TR_STATUS_CHECK_NEW);
end;

function TR_STATUS_DOWNLOAD_WAIT(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, -1, TR_STATUS_DOWNLOAD_WAIT_NEW);
end;

function TR_STATUS_DOWNLOAD(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, TR_STATUS_DOWNLOAD_OLD, TR_STATUS_DOWNLOAD_NEW);
end;

function TR_STATUS_SEED_WAIT(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, -1, TR_STATUS_SEED_WAIT_NEW);
end;

function TR_STATUS_SEED(RPCVer: Integer): Integer;
begin
  Result := Status(RPCVer, TR_STATUS_SEED_OLD, TR_STATUS_SEED_NEW);
end;

end.
