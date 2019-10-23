/**
 * The first frame can sometimes contain a LAME frame at the end of the Xing frame
 * <p/>
 * <p>This useful to the library because it allows the encoder to be identified, full specification
 * can be found at http://gabriel.mp3-tech.org/mp3infotag.html
 * <p/>
 * Summarized here:
 * 4 bytes:LAME
 * 5 bytes:LAME Encoder Version
 * 1 bytes:VNR Method
 * 1 bytes:Lowpass filter value
 * 8 bytes:Replay Gain
 * 1 byte:Encoding Flags
 * 1 byte:minimal byte rate
 * 3 bytes:extra samples
 * 1 byte:Stereo Mode
 * 1 byte:MP3 Gain
 * 2 bytes:Surround Dound
 * 4 bytes:MusicLength
 * 2 bytes:Music CRC
 * 2 bytes:CRC Tag
 */
package com.audioengine.format.mpeg
{
	import flash.utils.ByteArray;

	public class LAMEFrame
	{
		private static const LAME_ID : String = 'LAME';
		
		private static const LAME_VBR_METHODS : Vector.<String> = Vector.<String>( 
			 [ 
			   'unknown', 'cbr', 'abr', 'vbr old / vbr rh', 'vbr mtrh', 'vbr mt', '', 'cbr 2 pass', 'abr 2 pass', '',
			   '', '', '', '', ''
			 ]
			);
		
		/**
		 * LAME coder version 
		 */		
		private var _version : String;
		
		/**
		 * Info Tag revision  
		 */		
		private var _tagRevision   : int;
		/**
		 * VBR method id
		 */		
		private var _vbrMethodID   : int;
		/**
		 * VBR method string description 
		 */		
		private var _vbrMethod     : String;
		
		/**
		 * 	 Lowpass filter value in Hz  
		 */		
		private var _lowPassFilter : int;
		
		/**
		 * total samples codec added to start 
		 */		
		private var _encoderDelay : int;
		
		/**
		 * total samples codec added to end 
		 */		
		private var _encoderPadding : int;
		
		/**
		 * MusicLength in bytes 
		 */		
		private var _musicLength : int;
		
		public function LAMEFrame()
		{
		}
		
		public function get encoderDelay() : int
		{
			return _encoderDelay;
		}
		/*
		public function get MDCTEncoderDelay() : int
		{
			return _encoderDelay + 1681;
		}
		*/
		public function get encoderPadding() : int
		{
			return _encoderPadding;
		}
		/*
		public function get MDCTEncoderPadding() : int
		{
			return _encoderPadding - 529;
		}
		*/
		public function get musicLength() : int
		{
			return _musicLength;
		}	
		
		public function analyze( data : ByteArray ) : Boolean
		{
			//var pos  : int = data.position;
			var byte : int; 
			
			if ( data.readUTFBytes( 4 ) == LAME_ID )
			{
				_version = data.readUTFBytes( 5 );
				
				//Info Tag revision + VBR method 
				byte = data.readUnsignedByte();
				
				_tagRevision = byte & 0xF0;
				_vbrMethodID = byte & 0xF;
				_vbrMethod   = LAME_VBR_METHODS[ _vbrMethodID ];
				
				//Lowpass filter value
				byte = data.readUnsignedByte();
				_lowPassFilter = byte * 100;
				
				//Replay Gain
				data.readFloat() //Peak signal amplitude
				data.readUnsignedShort(); //Radio Replay Gain
				data.readUnsignedShort(); //Audiophile Replay Gain
				
				// Encoding flags + ATH Type
				byte = data.readUnsignedByte();
				
				//if ABR {specified bitrate} else {minimal bitrate}
				byte = data.readUnsignedByte();
				
				//Encoder delays (My magic digits :) Yahoo!!!
				extractEncoderDelay( data );
				
				//Misc 
				extractMisc( data );
				
				//MP3 Gain
				extractMP3Gain( data );
				
				//Preset and surround info
				extractPresetAndSurroundInfo( data );
				
				//MusicLength
				_musicLength = data.readUnsignedInt();
				
				//MusicCRC
				data.readUnsignedShort();
				
				//CRC-16 of Info Tag
				data.readUnsignedShort();
				
				return true;
			}	

			
			//data.position = pos;
			return false;
		}
		
		private function extractPresetAndSurroundInfo( data : ByteArray ) : void
		{
			data.readUnsignedShort();
		}	
		
		private function extractMP3Gain( data : ByteArray ) : void
		{
			data.readUnsignedByte();
		}	
		
		private function extractMisc( data : ByteArray ) : void
		{
			data.readUnsignedByte();
		}	
		
		private function extractEncoderDelay( data : ByteArray ) : void
		{
			var byte0 : int = data.readUnsignedByte();
			var byte1 : int = data.readUnsignedByte();
			var byte2 : int = data.readUnsignedByte();
			
			_encoderDelay = ( byte0 << 4 ) | ( ( byte1 & 0x00f0 ) >>4 );
			_encoderPadding = (( byte1 & 0x000f ) << 8 ) | byte2;
			
			/*
			// Adjust encoderDelay and encoderPadding for MDCT/filterbank delays
			_encoderDelay = encoderDelay + 528 + 1;
			_encoderPadding = encoderPadding - (528 + 1);
			*/
			
			_encoderDelay += 528 + 1 + 1152;
			_encoderPadding -= 528 + 1;
			
			//trace( 'lamePadding', _encoderDelay, _encoderPadding );
		}	
			
	}
}