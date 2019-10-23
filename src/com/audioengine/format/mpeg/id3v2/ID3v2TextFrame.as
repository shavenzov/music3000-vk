/**
 * Text information frames

   The text information frames are often the most important frames,
   containing information like artist, album and more. There may only be
   one text information frame of its kind in an tag. All text
   information frames supports multiple strings, stored as a null
   separated list, where null is reperesented by the termination code
   for the charater encoding. All text frame identifiers begin with "T".
   Only text frame identifiers begin with "T", with the exception of the
   "TXXX" frame. All the text information frames have the following
   format:

     <Header for 'Text information frame', ID: "T000" - "TZZZ",
     excluding "TXXX" described in 4.2.6.>
     Text encoding                $xx
     Information                  <text string(s) according to encoding> 
 */
package com.audioengine.format.mpeg.id3v2
{

	public class ID3v2TextFrame
	{
		/**
		 * ISO-8859-1 [ISO-8859-1]. Terminated with $00. 
		 */		
		public static const ISO_8859_1 : int = 0x00;
		/**
		 * UTF-16 [UTF-16] encoded Unicode [UNICODE] with BOM. All 
		 */		
		public static const UTF_16     : int = 0x01;
		/**
		 * UTF-16BE [UTF-16] encoded Unicode [UNICODE] without BOM. 
		 */		
		public static const UTF_16BE   : int = 0x02;
		/**
		 * UTF-8 [UTF-8] encoded Unicode [UNICODE] 
		 */		
		public static const UTF_8      : int = 0x03;
		
		private var _frame    : ID3v2Frame;
		
		public function ID3v2TextFrame( frame : ID3v2Frame )
		{
		   super();
		   _frame = frame;
		}
		
		public function get frame() : ID3v2Frame
		{
			return _frame;
		}	
		
		public function get encoding() : int
		{
			var _encoding : int = _frame.data.readUnsignedByte();
			_frame.data.position = 0;
			
			return _encoding;
		}	
		
		public function get text() : String
		{
			var _encoding : int = _frame.data.readUnsignedByte();
			var result    : String;
			
			result = _frame.data.readMultiByte( _frame.data.bytesAvailable, getEncodingDescription( _encoding ) );
			_frame.data.position = 0;
			
			return result;
		}
		
		public function set text( value : String ) : void
		{
			_frame.data.length = 0;
			_frame.data.writeByte( UTF_8 );
			_frame.data.writeMultiByte( value, getEncodingDescription( UTF_8 ) );
			_frame.data.position = 0;
		}	
		
		public static function getEncodingDescription( encoding : int ) : String
		{
			switch( encoding )
			{
				case UTF_16     :
				case UTF_16BE   : return 'unicode'; 
				case UTF_8      : return 'utf-8'; 	
				default         : return 'iso-8859-1';	
			}
		}	
	}
}