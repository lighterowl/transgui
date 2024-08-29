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

unit ConnOptionsPathsFrame;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, StdCtrls, Spin, Utils;

type

  { TConnOptionsPathsFrame }

  TConnOptionsPathsFrame = class(TFrame)
    edMaxFolder: TSpinEdit;
    edPaths: TMemo;
    Label1: TLabel;
    txPaths: TLabel;
  private

  public
    procedure LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
    procedure SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
    function IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
  end;

implementation

procedure TConnOptionsPathsFrame.LoadConnSettings(const Section: string; Ini: TIniFileUtf8);
begin
  edPaths.Text:=StringReplace(Ini.ReadString(Section, 'PathMap', ''), '|', LineEnding, [rfReplaceAll]);
  edMaxFolder.Value:= Ini.ReadInteger('Interface','MaxFoldersHistory', 50);
end;

procedure TConnOptionsPathsFrame.SaveConnSettings(const Section: string; Ini: TIniFileUtf8);
begin
  Ini.WriteInteger('Interface','MaxFoldersHistory', edMaxFolder.Value);
  Ini.WriteString(Section, 'PathMap', StringReplace(edPaths.Text, LineEnding, '|', [rfReplaceAll]));
end;

function TConnOptionsPathsFrame.IsConnSettingsChanged(const Section: string; Ini: TIniFileUtf8) : Boolean;
begin
  Result := (edPaths.Text <> StringReplace(Ini.ReadString(Section, 'PathMap', ''), '|', LineEnding, [rfReplaceAll]));
end;

initialization
  {$I connoptionspathsframe.lrs}

end.

