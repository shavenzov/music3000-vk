package com.audioengine.format.mpeg
{
	import com.audioengine.format.mpeg.events.MP3SoundEvent;
	import com.audioengine.format.mpeg.id3v2.ID3v2;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class MPEGAudio extends EventDispatcher
	{
		/**
		 *{ Limitation constants } 
		 */	
		/**
		 *{ Max. MPEG frame length } 
		 */		
		private static const MAX_MPEG_FRAME_LENGTH : int = 1729;                      
		/**
		 *{ Min. bit rate value } 
		 */		
		private static const MIN_MPEG_BIT_RATE : int = 8;
		/**
		 *{ Max. bit rate value } 
		 */		
		private static const MAX_MPEG_BIT_RATE : int = 448;                              
		/**
		 *{ Min. song duration value } 
		 */		
		private static const MIN_ALLOWED_DURATION : int = 0.1;
		
		private var _id3v2 : ID3v2;
		
		private var _xing  : XingFrame;
		private var _lame  : LAMEFrame;
		
		/**
		 * file size 
		 */		
		private var _size : int;
		
		/**
		 * list of MPEG frames 
		 */		
		private var _frames : Vector.<MPEGFrame>;
		
		public function MPEGAudio()
		{
		}
		
		public function get xing() : XingFrame
		{
		   return _xing;	
		}
		
		public function get lame() : LAMEFrame
		{
		   return _lame;	
		}	
		
		public function get id3v2() : ID3v2
		{
			return _id3v2;
		}
		
		public function set id3v2( value : ID3v2 ) : void
		{
			_id3v2 = value;
		}	
		
		public function get size() : int
		{
			return _size;
		}	
		
		public function analyze( data : ByteArray, generateSound : Boolean = false ) : void
		{
			_size = data.length;
			
			// looking for id3v2 header
			var id3v2 : ID3v2 = new ID3v2();
			
			if ( id3v2.analyze( data ) )
			{
				_id3v2 = id3v2;
				data.position = _id3v2.size;
			}
			else
			{
				data.position = 0;
			}
			
			// looking for audio frame with LAME Info
			var size4 : int = _size - 4;
			var pos : int;
			
			while( data.position < size4 )
			{
				pos = data.position;
				
				//Check Is it frame header?
				if ( MPEGFrame.isFrameHeader( data ) )
				{
					data.position -= 4;
					
					var frame : MPEGFrame = new MPEGFrame();
					    frame.analyze( data );
						
					if ( frame.xing )
					{
						if ( frame.xing.lame )
						{
							_xing = frame.xing;
							_lame = _xing.lame;
							
							if ( ! generateSound )
							{
								break;
							}
						}	
					}
				    
					if ( generateSound )
					{
						if ( ! _frames )
						{
							_frames = new Vector.<MPEGFrame>();
						}
						
						_frames.push( frame );
					}
					
					data.position = pos + frame.size;
				}
				else
				{
					if ( _frames && _frames.length > 0 )
					{
						data.position += _frames[ 0 ].size - 4;
					}
					
					//trace( "Can't find valid mpeg frames", data.position, _frames.length );
				}
			}
			
			if ( generateSound )
			{
				if ( _frames.length == 0 )
					throw new Error( "Can't find valid mpeg frames" );
				
				createSound( data );
				
				_frames.length = 0;
				_frames = null;
			}
			
			data.position = 0;
		}
		
		private function createSound( data : ByteArray ) : void
		{
			var byte : int;
			
			var swfBytes:ByteArray = new ByteArray();
			    swfBytes.endian    = Endian.LITTLE_ENDIAN;
			
			for each( byte in SoundClassSwfByteCode.soundClassSwfBytes1 )
			{
				swfBytes.writeByte( byte );
			}
				
			var swfSizePosition : uint = swfBytes.position;
			    swfBytes.writeInt(0); //swf size will go here
			
			for each( byte in SoundClassSwfByteCode.soundClassSwfBytes2 )
			{
				swfBytes.writeByte( byte );
			}
				
			var audioSizePosition : uint = swfBytes.position;
			swfBytes.writeInt(0); //audiodatasize+7 to go here
			swfBytes.writeByte(1);
			swfBytes.writeByte(0);
			
			
			var sampleRateIndex : uint = 4 - ( 44100 / _frames[ 0 ].sampleRate );
			swfBytes.writeByte((2<<4)+(sampleRateIndex<<2)+(1<<1)+(_frames[ 0 ].channels-1));
			
			var sampleSizePosition : uint = swfBytes.position;
			swfBytes.writeInt(0); //number of samples goes here
			
			swfBytes.writeByte(0); //seeksamples
			swfBytes.writeByte(0);
			
			var byteCount:uint=0; //this includes the seeksamples written earlier
			
			for each( var frame : MPEGFrame in _frames )
			{
			  swfBytes.writeBytes( data, frame.position, frame.size );
			  byteCount += frame.size;
			}
			
			byteCount += 2;
			
			var currentPos : uint = swfBytes.position;
			swfBytes.position = audioSizePosition;
			swfBytes.writeInt( byteCount + 7 );
			swfBytes.position = sampleSizePosition;
			swfBytes.writeInt( _frames.length * 1152 );
			swfBytes.position = currentPos;
			
			for each( byte in SoundClassSwfByteCode.soundClassSwfBytes3 )
			{
				swfBytes.writeByte( byte );	
			}
			
			swfBytes.position=swfSizePosition;
			swfBytes.writeInt( swfBytes.length );
			swfBytes.position=0;
			
			var swfBytesLoader:Loader=new Loader();
			swfBytesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,swfCreated);
			swfBytesLoader.loadBytes(swfBytes);
		}
		
		private function swfCreated(ev:Event):void
		{
			var loaderInfo:LoaderInfo=ev.currentTarget as LoaderInfo;
			var soundClass:Class=loaderInfo.applicationDomain.getDefinition("SoundClass") as Class;
			var sound:Sound=new soundClass();
			dispatchEvent( new MP3SoundEvent (MP3SoundEvent.COMPLETE,sound ) );
		}
	}
}