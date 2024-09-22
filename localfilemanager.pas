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

unit LocalFileManager;

{$mode ObjFPC}{$H+}{$J-}
{$ifdef darwin}
{$modeswitch objectivec1}
{$endif}

interface

uses SysUtils, Dialogs
{$if defined(linux)}
, dbus
{$elseif defined(darwin)}
, CocoaAll
{$endif}
;

procedure ShowFile(Path: string);

implementation

type
  EFileManagerError = class(Exception);

{$if defined(linux)}

procedure ShowFile_impl(Path : string);
var
  err: DBusError;
  conn: PDBusConnection;
  msg, replymsg: PDBusMessage;
  args: DBusMessageIter;
  array_iter: DBusMessageIter;
  uri_p, startupId: PChar;
  uri: UTF8String;
  dbus_rv: dbus_bool_t;

  procedure Cleanup;
  begin
    dbus_error_free(@err);
    if replymsg <> nil then dbus_message_unref(replymsg);
    if msg <> nil then dbus_message_unref(msg);
    if conn <> nil then dbus_connection_unref(conn);
  end;

  procedure ReportCustomError(customMsg : string);
  begin
    Cleanup;
    raise EFileManagerError.Create(customMsg);
  end;

  procedure ReportDBusError;
  begin
    ReportCustomError(err.message);
  end;

begin
  uri := 'file://' + path;
  uri_p := PChar(uri);
  startupId := '';
  conn := nil;
  msg := nil;
  replymsg := nil;

  dbus_error_init(@err);

  conn := dbus_bus_get(DBUS_BUS_SESSION, @err);
  if conn = nil then ReportDBusError;

  msg := dbus_message_new_method_call('org.freedesktop.FileManager1',
  '/org/freedesktop/FileManager1', 'org.freedesktop.FileManager1', 'ShowItems');
  if msg = nil then ReportDBusError;

  dbus_message_iter_init_append(msg, @args);

  dbus_rv := dbus_message_iter_open_container(@args, DBUS_TYPE_ARRAY, DBUS_TYPE_STRING_AS_STRING, @array_iter);
  if dbus_rv <> 0 then ReportCustomError('iter_open_container returned null');

  dbus_rv := dbus_message_iter_append_basic(@array_iter, DBUS_TYPE_STRING, @uri_p);
  if dbus_rv <> 0 then ReportCustomError('iter_append_basic returned null');

  dbus_rv := dbus_message_iter_close_container(@args, @array_iter);
  if dbus_rv <> 0 then ReportCustomError('iter_close_container returned null');

  dbus_rv := dbus_message_iter_append_basic(@args, DBUS_TYPE_STRING, @startupId);
  if dbus_rv <> 0 then ReportCustomError('iter_append_basic returned null');

  replymsg := dbus_connection_send_with_reply_and_block(conn, msg, 1000, @err);
  if replymsg = nil then ReportDBusError;

  Cleanup;
end;

{$elseif defined(darwin)}
procedure ShowFile_impl(Path : string);
var
  u8path: UTF8String;
begin
  u8path := Path;
  NSWorkspace.sharedWorkspace.activateFileViewerSelectingURLs(
    NSArray.arrayWithObject(
      NSURL.fileURLWithPath(
        NSString.stringWithUTF8String(PChar(u8path)))));
end;

{$endif}

procedure ShowFile(Path: string);
begin
  try
    if Length(Path) = 0 then exit;

    ShowFile_impl(Path);
  except
    on e: EFileManagerError do
      ShowMessage('Failed to show file in file manager :' + sLineBreak + e.Message);
  end;
end;

end.
