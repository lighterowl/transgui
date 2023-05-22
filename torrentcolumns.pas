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

unit TorrentColumns;

{$mode ObjFPC}{$H+}{$J-}

// definitions of column indices in TMainForm.FTorrents

interface

const

torcolName = 0;
torcolSize = 1;
torcolDone = 2;
torcolStatus = 3;
torcolSeeds = 4;
torcolPeers = 5;
torcolDownSpeed = 6;
torcolUpSpeed = 7;
torcolETA = 8;
torcolRatio = 9;
torcolDownloaded = 10;
torcolUploaded = 11;
torcolTracker = 12;
torcolTrackerStatus = 13;
torcolAddedOn = 14;
torcolCompletedOn = 15;
torcolLastActive = 16;
torcolPath = 17;
torcolPriority = 18;
torcolSizeToDowload = 19;
torcolTorrentId = 20;
torcolQueuePos = 21;
torcolSeedingTime = 22;
torcolSizeLeft = 23;
torcolPrivate = 24;
torcolLabels = 25;

torcolTag = -1;
torcolSeedsTotal = -2;
torcolLeechersTotal = -3;
torcolStateImg = -4;
torcolDeleted = -5;
torcolDownSpeedHistory = -6;
torcolUpSpeedHistory = -7;
TorrentsExtraColumns = torcolUpSpeedHistory * -1;

implementation

end.
