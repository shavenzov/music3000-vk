package com.audioengine.format.mpeg
{
	import flash.utils.ByteArray;

	public class XingFrame
	{
		//The offset into first frame varies based on the MPEG frame properties
		private static const  MPEG_VERSION_1_MODE_MONO_OFFSET   : int = 21;
		private static const  MPEG_VERSION_1_MODE_STEREO_OFFSET : int = 36;
		private static const  MPEG_VERSION_2_MODE_MONO_OFFSET   : int = 13;
		private static const  MPEG_VERSION_2_MODE_STEREO_OFFSET : int = 21;
		
		private static const XING_VBR_ID : String = 'Xing';
		private static const XING_CBR_ID : String = 'Info';
		
		/**
		 * if set to true - variable bitrate else constant bitrate 
		 */		
		private var _vbr : Boolean
		
		private var _flags  : int;
		private var _frames : int;
		private var _bytes  : int;
		private var _scale  : int;
		
		private var _lame   : LAMEFrame;
		
		
		public function XingFrame()
		{
		}
		
		public function get vbr() : Boolean
		{
			return _vbr;
		}
		
		public function get flags() : int
		{
			return _flags;
		}
		
		public function get frames() : int
		{
			return _frames;
		}
		
		public function get bytes() : int
		{
			return _bytes;
		}
		
		public function get scale() : int
		{
			return _scale;
		}	
		
		public function get lame() : LAMEFrame
		{
			return _lame;
		}	
		
		/**
		 * parse frame and return false if it't not XingFrame 
		 * @param data
		 * @return 
		 * 
		 */		
		public function analyze( data : ByteArray, frame : MPEGFrame ) : Boolean
		{
			//var startPos : int = data.position;
			
			if ( frame.versionID == MPEGFrame.MPEG_VERSION_1 )
			{
				if ( frame.channelModeID == MPEGFrame.MPEG_CM_MONO )
				{
					data.position += MPEG_VERSION_1_MODE_MONO_OFFSET;
				}
				else
				{
					data.position += MPEG_VERSION_1_MODE_STEREO_OFFSET;
				}	
			}
			else
			{
				if ( frame.channelModeID == MPEGFrame.MPEG_CM_MONO )
				{
					data.position += MPEG_VERSION_2_MODE_MONO_OFFSET;
				}
				else
				{
					data.position += MPEG_VERSION_2_MODE_STEREO_OFFSET;
				}
			}
			
			var id : String = data.readUTFBytes( 4 );
			
			if ( ( id == XING_VBR_ID ) || ( id == XING_CBR_ID ) )
			{
				_vbr = ( id == XING_VBR_ID );
				
				//flags
				_flags = data.readUnsignedInt();
				
				//frames
				_frames = data.readUnsignedByte() * 0x1000000 +
					      data.readUnsignedByte() * 0x10000   +
						  data.readUnsignedByte() * 0x100     +
						  data.readUnsignedByte();
				
				//bytes
				_bytes = data.readUnsignedByte() * 0x1000000 +
					     data.readUnsignedByte() * 0x10000   +
					     data.readUnsignedByte() * 0x100     +
					     data.readUnsignedByte();
				
				//skip 100 bytes
				data.position += 100;
				
				//scale (quality)
				_scale = data.readUnsignedInt();
				
				var lame : LAMEFrame = new LAMEFrame();
				
				if ( lame.analyze( data ) )
				{
					_lame = lame;
				}	
				
				return true;
			}
			
			return false;
		}
	}
}