﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Net;
using System.Net.Sockets;
using UnityEngine;

namespace RocketNet
{
    /// <summary>
    /// GNU Rocket client/player device
    /// </summary>
    public class Device
    {
        /// <summary>
        /// Default port for the editor
        /// </summary>
        public const int DefaultPort = 1338;

        /// <summary>
        /// Function for opening files for read (when loading tracks in player mode). You can plug your own eg. packfile open function here.
        /// </summary>
        public Func<string, Stream> OpenStreamRead = File.OpenRead;

        /// <summary>
        /// Function for opening files for write (when saving tracks). You can plug your own open function here.
        /// </summary>
        public Func<string, Stream> OpenStreamWrite = File.OpenWrite;

        /// <summary>
        /// Function that gets called when the editor wants to change the current row
        /// </summary>
        public Action<int> SetRow;

        /// <summary>
        /// Function that gets called when the editor wants to pause/unpause the demo
        /// </summary>
        public Action<bool> Pause;

        /// <summary>
        /// Function that returns if the demo is currently playing
        /// </summary>
        public Func<bool> IsPlaying;

        /// <summary>
        /// Device constructor.
        /// </summary>
        /// <param name="base">Base name/path for track files</param>
        /// <param name="isPlayer">Player mode (false: Client, true: Player)</param>
        public Device(string @base, bool isPlayer)
        {
            this.@base = @base;
            player = isPlayer;
        }

        public void Update()
        {
            int a = 0;
        }

        /// <summary>
        /// Dispose the device (only important in client mode)
        /// </summary>
        public void Dispose()
        {
            Close();
        }

        /// <summary>
        /// Connect to editor application (client mode only!)
        /// </summary>
        /// <param name="host">Host name for the editor app</param>
        /// <param name="port">Port for the editor app</param>
        /// <returns>Success yes/no</returns>
        public bool Connect(string host = "localhost", int port = DefaultPort)
        {
            if (player) throw new InvalidOperationException("Connect is only possible in client mode");
            Close();

            // connect to editor
            sock = ServerConnect(host, port);
            if (sock == null)
                return false;

            // refresh track data
            foreach (var track in tracks)
            {
                if (!GetTrackData(track))
                    return false;
            }

            row = -1;
            return true;
        }

        /// <summary>
        /// Client update. Call once per frame in client mode.
        /// </summary>
        /// <param name="row">Current row</param>
        /// <returns>Success yes/no. If no it might be a good idea to try to reconnect to the editor</returns>
        public bool Update(int row)
        {
            if (player) return true;

            // parse command coming from editor
            while (sock != null && sock.Poll(0, SelectMode.SelectRead))
            {
                if (!Receive(1)) return false;
                var cmd = (Command)buffer[0];

                switch(cmd)
                {
                    case Command.SetKey:
                        OnSetKey();
                        break;
                    case Command.DeleteKey:
                        OnDelKey();
                        break;
                    case Command.SetRow:
                        if (!Receive(4)) return false;
                        if (SetRow != null)
                            SetRow(IPAddress.NetworkToHostOrder(BitConverter.ToInt32(buffer, 0)));
                        break;
                    case Command.Pause:
                        if (!Receive(1)) return false;
                        if (Pause != null)
                            Pause(buffer[0] != 0);
                        break;
                    case Command.SaveTracks:
                        SaveTracks();
                        break;
                    default:
                        Close();
                        throw new InvalidOperationException("Unknown command " + buffer[0]);
                }
            }

            bool actionIsPlaying = IsPlaying != null;
            bool actionIsPlayingFunc = actionIsPlaying && IsPlaying();
            bool rowIsDifferent = row != this.row;
            bool isSock = sock != null;
            // send row update to editor if applicable
            if ( rowIsDifferent && isSock)
            {
                // per-frame alloc. meh. :(
                var cmdbuf = new[] { (byte)Command.SetRow };
                var rowbuf = BitConverter.GetBytes(IPAddress.HostToNetworkOrder(row));
                this.row = row;

                Send(cmdbuf, rowbuf);
            }

            return sock != null;
        }

        /// <summary>
        /// Get track data
        /// </summary>
        /// <param name="name">Track name</param>
        /// <returns>Track data</returns>
        public Track GetTrack(string name)
        {
            var track = tracks.Find(t => t.name == name);

            // no track found? create new one and load data.
            if (track == null)
            {
                track = new Track { name = name };
                tracks.Add(track);
                GetTrackData(track);
            }

            return track;
        }
       
        /// <summary>
        /// Save all tracks to .track files
        /// </summary>
        public void SaveTracks()
        {
            foreach (var track in tracks)
            {
                var s = OpenStreamWrite(MakeTrackPath(track.name));
                track.Save(s);
            }
        }

        // retrieve data for a track
        bool GetTrackData(Track t)
        {
            if (player)
            {
                // Player: load .track file
                var s = OpenStreamRead(MakeTrackPath(t.name));
                t.Load(s);
                return true;
            }
            else if (sock != null)
            {
                // Client: send track data request to editor
                // Editor will respond with a series of SetKey commands
                var cmd = new[] { (byte)Command.GetTrack };
                var nameLen = BitConverter.GetBytes(IPAddress.HostToNetworkOrder(t.name.Length));
                var nameBuf = Encoding.ASCII.GetBytes(t.name);
                return Send(cmd, nameLen, nameBuf);
            }
            else
                return false;
        }

        // parse SetKey command from editor
        void OnSetKey()
        {
            if (!Receive(13)) return;

            // get key
            var track = IPAddress.NetworkToHostOrder(BitConverter.ToInt32(buffer, 0));
            var key = new Track.Key
            {
                row = IPAddress.NetworkToHostOrder(BitConverter.ToInt32(buffer, 4)),
                value = Int2Float(IPAddress.NetworkToHostOrder(BitConverter.ToInt32(buffer, 8))),
                type = (Track.Key.Type)buffer[12],
            };
          
            // ... and set it
            tracks[track].SetKey(key);
        }
       
        // parse DelKey command from editor
        void OnDelKey()
        {
            if (!Receive(8)) return;
           
            // get track/row
            var track = IPAddress.NetworkToHostOrder(BitConverter.ToInt32(buffer, 0));
            var row = IPAddress.NetworkToHostOrder(BitConverter.ToInt32(buffer, 4));

            // ... and delete.
            tracks[track].DeleteKey(row);
        }

        // Receive a number of bytes into buffer, close socket if there's an error
        bool Receive(int length)
        {
            try
            {
                if (sock.Receive(buffer, length, SocketFlags.None) != length)
                {
                    Close();
                    return false;
                }
            }
            catch (SocketException)
            {
                Close();
                return false;
            }
            return true;
        }

        // send all the specified buffers, close socket if there's an error
        bool Send(params byte[][] buffers)
        {
            foreach (var b in buffers)
            {
                try
                {
                    if (sock.Send(b) != b.Length)
                    {
                        Close();
                        return false;
                    }
                }
                catch (SocketException)
                {
                    Close();
                    return false;
                }
            }

            return true;
        }
        
        // close the socket
        void Close()
        {
            if (sock != null)
            {
                sock.Close();
                sock = null;
            }
        }

        // make file name for a track
        string MakeTrackPath(string name)
        {
            return @base + "_" + name + ".track";
        }

        // reinterpret 32bit int as float (same bits)
        static float Int2Float(int i)
        {
            // slowest method ever but "weird stuff" free :)
            return BitConverter.ToSingle(BitConverter.GetBytes(i), 0);
        }

        // try to connect to a server and return socket
        static Socket ServerConnect(string host, int port)
        {
            // try all resolved addresses for the host...
            foreach (var addr in Dns.GetHostAddresses(host))
            {
                Socket sock;
                try
                {
                    sock = new Socket(addr.AddressFamily, SocketType.Stream, ProtocolType.Tcp);
                    sock.NoDelay = true;
                }
                catch (SocketException)
                {
                    continue;
                }

                try
                {
                    // connect
                    sock.Connect(addr, port);

                    // perform handshake: send client greet, check for server greet
                    var cGreet = Encoding.ASCII.GetBytes(ClientGreet);
                    var sGreet = Encoding.ASCII.GetBytes(ServerGreet);                    
                    var recbuf = new byte[sGreet.Length];

                    if (sock.Send(cGreet) < cGreet.Length ||
                        sock.Receive(recbuf) < recbuf.Length ||
                        !recbuf.SequenceEqual(sGreet))
                    {
                        sock.Close();
                        continue;
                    }

                    return sock;
                }
                catch (SocketException)
                {
                    sock.Close();
                }
                catch (Exception)
                {
                    throw;
                }
            }
            return null;
        }

        const string ClientGreet = "hello, synctracker!";
        const string ServerGreet = "hello, demo!";

        enum Command 
        {
	        SetKey = 0,
	        DeleteKey = 1,
	        GetTrack = 2,
	        SetRow = 3,
	        Pause = 4,
	        SaveTracks = 5
        };

        string @base;
        public bool player;

        List<Track> tracks = new List<Track>();

        // client only
        byte[] buffer = new byte[512];
        int row;
        Socket sock;
    }
}
