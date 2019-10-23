package com.audioengine.format.mpeg
{
	import flash.utils.ByteArray;

	public class MPEGFrame
	{
		/**
		 * { Table for bit rates } 
		 */		
		private static const MPEG_BIT_RATE : Array =
		[
			//For MPEG 2.5
			[[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
		     [ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 ],
		     [ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 ],
			 [ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 ]],
			//Reserved 
			[[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
			 [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
			 [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
			 [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]],
			//For MPEG 2
			[[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
			 [ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 ],
			 [ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 ],
			 [ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 ]],
			//For MPEG 1
			[[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
			 [ 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0 ],
			 [ 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0 ],
			 [ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0 ]]
		];
		
		/**
		 *Sample rate codes 
		 */
		/**
		 *  Level 3 
		 */		
		private static const MPEG_SAMPLE_RATE_LEVEL_3 : int = 0;                                    
		/**
		 *Level 2 
		 */		
		private static const MPEG_SAMPLE_RATE_LEVEL_2 : int = 1; 
		/**
		 *Level 1 
		 */		
		private static const MPEG_SAMPLE_RATE_LEVEL_1 : int = 2;                                   
		/**
		 *Unknown value 
		 */		
		private static const MPEG_SAMPLE_RATE_UNKNOWN : int = 3;
		
		
		/**
		 *{ Table for sample rates } 
		 */		
		private static const MPEG_SAMPLE_RATE : Array =
		[
			[11025, 12000, 8000, 0],                                   //{ For MPEG 2.5 }
			[0, 0, 0, 0],                                                  //{ Reserved }
			[22050, 24000, 16000, 0],                                    //{ For MPEG 2 }
			[44100, 48000, 32000, 0]                                     //{ For MPEG 1 }
		];
		
		
		/**
		 * { MPEG version codes } 
		 */
		/**
		 * MPEG 2.5 
		 */		
		public static const MPEG_VERSION_2_5 : int = 0;                                         
		
		/**
		 *Unknown version 
		 */		
		public static const MPEG_VERSION_UNKNOWN : int = 1;                                
		
		/**
		 *  MPEG 2 
		 */		
		public static const MPEG_VERSION_2 : int = 2;                                               
		
		/**
		 * MPEG 1  
		 */		
		public static const MPEG_VERSION_1 : int = 3;                                            
		
		
		/**
		 * { MPEG version names }
		 */		
		private static const MPEG_VERSION : Vector.<String> = Vector.<String>( 
		 [ 'MPEG 2.5', 'MPEG ?', 'MPEG 2', 'MPEG 1' ]
		); 
			
		
		
		
		/**
		 * { MPEG layer codes } 
		 */
		/**
		 * { Unknown layer } 
		 */		
		private static const MPEG_LAYER_UNKNOWN : int = 0;                                     
		/**
		 *   { Layer III } 
		 */		
		private static const MPEG_LAYER_III : int = 1;                                           
		/**
		 * { Layer II } 
		 */		
		private static const MPEG_LAYER_II : int = 2;                                               
		/**
		 * { Layer I } 
		 */		
		private static const MPEG_LAYER_I : int = 3;                                                 
		
		/**
		 * { MPEG layer names } 
		 */		
		private static const MPEG_LAYER : Vector.<String> = Vector.<String>(
			[ 'Layer ?', 'Layer III', 'Layer II', 'Layer I' ]
		   );
		
		
		
		
		/**
		 * { Channel mode codes } 
		 */
		/**
		 * { Stereo } 
		 */		
		public static const MPEG_CM_STEREO : int = 0;
		/**
		 *{ Joint Stereo } 
		 */		
		public static const MPEG_CM_JOINT_STEREO : int = 1; 
		/**
		 *{ Dual Channel } 
		 */		
		public static const MPEG_CM_DUAL_CHANNEL : int = 2;
		/**
		 *{ Mono } 
		 */		
		public static const MPEG_CM_MONO : int = 3;                                                    
		/**
		 * { Unknown mode } 
		 */		
		public static const MPEG_CM_UNKNOWN : int = 4; 
		
		/**
		 * 	{ Channel mode names }
		 */
		private static const MPEG_CM_MODE : Vector.<String> = Vector.<String>(
		 [ 'Stereo', 'Joint Stereo', 'Dual Channel', 'Mono', 'Unknown' ]	
		);
		
		
		
		
		/**
		 *{ Extension mode codes (for Joint Stereo) } 
		 */		
		/**
		 *{ IS and MS modes set off } 
		 */		
		private static const MPEG_CM_EXTENSION_OFF : int = 0;                        
		/**
		 * { Only IS mode set on } 
		 */		
		private static const MPEG_CM_EXTENSION_IS : int = 1;                            
		/**
		 * { Only MS mode set on }
		 */		
		private static const MPEG_CM_EXTENSION_MS : int = 2;
		/**
		 * { IS and MS modes set on }
		 */		
		private static const MPEG_CM_EXTENSION_ON : int = 3;                          
		/**
		 * { Unknown extension mode } 
		 */		
		private static const MPEG_CM_EXTENSION_UNKNOWN : int = 4;
		
		
		
		/**
		 *  { Emphasis mode codes }
		 */		
		/**
		 * { None } 
		 */		
		private static const MPEG_EMPHASIS_NONE : int = 0;                                              
		/**
		 *   { 50/15 ms } 
		 */		
		private static const MPEG_EMPHASIS_5015 : int = 1; 
		/**
		 * { Unknown emphasis } 
		 */		
		private static const MPEG_EMPHASIS_UNKNOWN : int = 2;                               
		/**
		 * { CCIT J.17 } 
		 */		
		private static const MPEG_EMPHASIS_CCIT  : int= 3;
		
		/**
		 *{ Emphasis names } 
		 */		
		private static const MPEG_EMPHASIS : Vector.<String> = Vector.<String>(
			[ 'None', '50/15 ms', 'Unknown', 'CCIT J.17' ]
			);
			
		
		
		
		/**
		 * { Encoder codes } 
		 */
		/**
		 * { Unknown encoder } 
		 */		
		private static const MPEG_ENCODER_UNKNOWN : int = 0;                                 
		/**
		 *{ Xing } 
		 */		
		private static const MPEG_ENCODER_XING : int = 1;                                               
		/**
		 * { FhG } 
		 */		
		private static const MPEG_ENCODER_FHG : int = 2;                                                 
		/**
		 * { LAME } 
		 */		
		private static const MPEG_ENCODER_LAME : int = 3;
		/**
		 * { Blade } 
		 */		
		private static const MPEG_ENCODER_BLADE : int = 4;                                             
		/**
		 * { GoGo } 
		 */		
		private static const MPEG_ENCODER_GOGO : int = 5;                                               
		/**
		 * { Shine } 
		 */		
		private static const MPEG_ENCODER_SHINE : int = 6;                                             
		/**
		 * { QDesign } 
		 */		
		private static const MPEG_ENCODER_QDESIGN : int = 7;                                         
		
		/**
		 *  { Encoder names }
		 */		
		private static const MPEG_ENCODER : Vector.<String> = Vector.<String>(
			[ 'Unknown', 'Xing', 'FhG', 'LAME', 'Blade', 'GoGo', 'Shine', 'QDesign' ]
			);
			
		
		/**
		 * Extracted information about Frame 
		 */
		/**
		 *{ MPEG version ID } 
		 */		
		private var _versionID : int;
		/**
		 * { MPEG layer ID } 
		 */		
		private var _layerID : int;
		/**
		 *{ True if protected by CRC } 
		 */		
		private var _protectionBit : Boolean;
		/**
		 * { Bit rate ID }
		 */		
		private var _bitRateID : int;
		/**
		 * { Sample rate ID } 
		 */		
		private var _sampleRateID : int;
		/**
		 *{ True if frame padded } 
		 */		
		private var _paddingBit : Boolean;
		/**
		 * { Extra information } 
		 */		
		private var _privateBit : Boolean;
		/**
		 *{ Channel mode ID } 
		 */		
		private var _channelModeID : int;
		/**
		 * { Mode extension ID (for Joint Stereo) } 
		 */		
		private var _modeExtensionID : int;
		/**
		 * { True if audio copyrighted } 
		 */		
		private var _copyrightBit : Boolean;
		/**
		 * { True if original media } 
		 */		
		private var _originalBit : Boolean;
		/**
		 * { Emphasis ID } 
		 */		
		private var _emphasisID : int;
		
		
		private var _vbr : VBRFrame;
		
		
		/**
		 * Calculated parameters about frame 
		 */		
		private var _coefficient : int;
		private var _bitRate     : int;
		private var _sampleRate  : int;
		private var _padding     : int;
		/**
		 * Frame size (bytes)
		 */		
		private var _size : uint;
		
		/**
		 * position in ByteArray 
		 */		
		private var _position : uint;
		
		/**
		 * if frame contains XING frame 
		 */		
		private var _xing : XingFrame; 
		
		public function MPEGFrame()
		{
		}
		
		public function get xing() : XingFrame
		{
			return _xing;
		}	
		
		public function get channelModeID() : int
		{
			return _channelModeID;
		}
		
		public function get channels() : int
		{
			return _channelModeID > 2 ? 1 : 2;
		}
		
		public function get sampleRate() : int
		{
			return _sampleRate;
		}
		
		public function get versionID() : int
		{
			return _versionID;
		}
		
		public function get size() : int
		{
			return _size;
		}
		
		public function get position() : uint
		{
			return _position;
		}
		
		public function analyze( data : ByteArray ) : void
		{
			_position = data.position;
			
			/*var byte0 : int =*/ data.readUnsignedByte();
			var byte1 : int = data.readUnsignedByte();
			var byte2 : int = data.readUnsignedByte();
			var byte3 : int = data.readUnsignedByte();
			
			//extract information
			_versionID         = ( byte1 >> 3 ) & 3;
			_layerID           = ( byte1 >> 1 ) & 3;
			_protectionBit     = ( byte1 & 1) != 1;
			_bitRateID         =   byte2 >> 4;
			_sampleRateID      = ( byte2 >> 2) & 3;
	        _paddingBit        = ( ( byte2 >> 1 ) & 1 ) == 1;
			_privateBit        = ( byte2 & 1) == 1;
			_channelModeID     = ( byte3 >> 6) & 3;
			_modeExtensionID   = ( byte3 >> 4 ) & 3;
			_copyrightBit      = (( byte3 >> 3) & 1 ) == 1;
			_originalBit       = ( ( byte3 >> 2 ) & 1) == 1;
			_emphasisID        = byte3 & 3;
			
			//calculate parameters
			_coefficient = getCoefficient( _versionID, _layerID );
			_bitRate     = getBitRate( _versionID, _layerID, _bitRateID );
			_sampleRate  = getSampleRate( _versionID, _sampleRateID );
			_padding     = getPadding( _paddingBit, _layerID );
			_size        = getFrameLength( _coefficient, _bitRate, _sampleRate, _padding );
			
			//Back to header start pos
			data.position -= 4;
			
			//extract Xing frame information
			var xing : XingFrame = new XingFrame();
			
			if ( xing.analyze( data, this ) )
			{
				_xing = xing;
			}	
			
			
			//VBR Info if exists
			/*
			var vbr : VBRFrame = new VBRFrame();
			if ( vbr.analyze( data ) )
			{
				_vbr = vbr;
			}
			*/
		}
		
		private function getFrameLength( _coefficient : int, _bitRate : int, _sampleRate : int, _padding : int ) : int
		{
			return int( _coefficient * _bitRate * 1000 / _sampleRate) + _padding;
		}
		
		/**
		 * { Get frame size coefficient } 
		 * @return 
		 * 
		 */		
		private function getCoefficient( _versionID : int, _layerId : int ) : int
		{
		  if ( _versionID == MPEG_VERSION_1 )
		  {
			if ( _layerID == MPEG_LAYER_I )
			{
				return 48;
			}
			else return 144;
		  }	
		  else
		  {
			  if ( _layerID == MPEG_LAYER_I ) return 24;
			   else if ( _layerID == MPEG_LAYER_II ) return 144;
			    else return 72;
		  }
		}
		
		/**
		 * { Get bit rate } 
		 * @return 
		 * 
		 */		
		private function getBitRate( _versionID : int, _layerID : int, _bitRateID : int ) : int
		{
			return  MPEG_BIT_RATE[ _versionID ][ _layerID ][ _bitRateID ];
		}	
		
		/**
		 *{ Get sample rate } 
		 * @return 
		 * 
		 */		
		private function getSampleRate( _versionID : int, _sampleRateID : int ) : int
		{
			return MPEG_SAMPLE_RATE[ _versionID ][ _sampleRateID ];
		}	
		
		/**
		 * { Get frame padding } 
		 * @return 
		 * 
		 */		
		private function getPadding( _paddingBit : Boolean, _layerID : int ) : int
		{
			if ( _paddingBit )
			{
				if ( _layerID == MPEG_LAYER_I )
				{
					return 4;
				}
				else return 1
			}
			else return 0;
		}
		
		/**
		 * Check for valid frame header 
		 * @param data - frameHeader data
		 * @return true if is it header
		 * 
		 */		
		public static function isFrameHeader( data : ByteArray ) : Boolean
		{
			var byte0 : int = data.readUnsignedByte();
			var byte1 : int = data.readUnsignedByte();
			var byte2 : int = data.readUnsignedByte();
			var byte3 : int = data.readUnsignedByte();
			
			return ! ( (( byte0 & 0xFF ) != 0xFF ) ||
				       (( byte1 & 0xE0 ) != 0xE0 ) ||
				        ((( byte1 >> 3) & 3) == 1) ||
				        ((( byte1 >> 1) & 3) == 0) ||
				        (( byte2 & 0xF0) == 0xF0) ||
				        (( byte2 & 0xF0) == 0) ||
				        ((( byte2 >> 2) & 3) == 3) ||
				        (( byte3 & 3) == 2) );
		}
	}
}