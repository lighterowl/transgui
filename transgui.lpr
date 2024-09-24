{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2019 by Yury Sidorov and Transmission Remote GUI working group.
  Copyright (c) 2023-2024 by Daniel Kamil Kozar

  Transmission Remote GUI is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Transmission Remote GUI is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  In addition, as a special exception, the copyright holders give permission to 
  link the code of portions of this program with the
  OpenSSL library under certain conditions as described in each individual
  source file, and distribute linked combinations including the two.

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*************************************************************************************}

program transgui;

{$mode objfpc}{$H+}

uses
{$ifdef UNIX}
  cthreads,
  {$ifdef darwin}
  maclocale,
  {$else}
  clocale,
  {$endif}
{$endif}
  Interfaces, Forms, Main, rpc, AddTorrent, LazLogger,
  ConnOptions, varlist, TorrProps, DaemonOptions, About, IpResolver, download,
  ColSetup, utils, ResTranslator, AddLink, MoveTorrent, AddTracker, Options,
  passwcon, ConnOptionsTransmissionFrame, ConnOptionsProxyFrame,
  ConnOptionsPathsFrame, ConnOptionsMiscFrame, ConnOptionsFrames, LocalFileManager;

{$R *.res}

begin
  if not CheckAppParams then exit;

  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
