package com.audioengine.format.mpeg.id3v2
{
	import flash.utils.ByteArray;
	import flash.utils.ByteArray;
	
	public class ID3v2
	{
		private static const ID3HEADER : String = 'ID3';
		public static const HEADER_SIZE : int = 10;
		
		/**
		 * { Code for ID3v2.2.x tag } don't support in class!!!
		 */		
		private static const TAG_VERSION_2_2 : int = 2;                               
		/**
		 * { Code for ID3v2.3.x tag } 
		 */		
		private static const TAG_VERSION_2_3 : int = 3;                               
		/**
		 * { Code for ID3v2.4.x tag }
		 */		
		private static const TAG_VERSION_2_4 : int = 4;                               
		
		private var _version  : int = 0;
		private var _revision : int = 0;
		private var _size     : int;
		
		private var _unsynchronizationFlag : Boolean;
		private var _extendedHeaderFlag    : Boolean;
		private var _experimentalFlag      : Boolean;
		private var _footerPresent         : Boolean;
		
		private var _frames : Vector.<ID3v2Frame> = new Vector.<ID3v2Frame>;
		
		public function ID3v2()
		{
		  super();
		}
		
		public function get version() : int
		{
			return _version;
		}
		
		public function get revision() : int
		{
			return _revision;
		}	
		
		public function get size() : int
		{
			return _size;
		}	
		
		public function removeAllFrames() : void
		{
			_frames.length = 0;
		}
		
		public function addTextFrame( id : String, text : String ) : void
		{
			var textFrame : ID3v2TextFrame = new ID3v2TextFrame( new ID3v2Frame( id ) );
			    textFrame.text = text;
				
			_frames.push( textFrame.frame );	
		}	
		
		public function addFrame( frame : ID3v2Frame ) : void
		{
			_frames.push( frame );
		}
		
		public function getFrame( id : String ) : ID3v2Frame
		{
			for each ( var frame : ID3v2Frame in _frames )
			{
				if ( frame.id == id )
				 return frame;	
			}
			
			return null;
		}	
		
		private function getFramesSize() : int
		{
			var result : int = 0;
			var i      : int = 0;
			
			while( i < _frames.length )
			{
				var frame : ID3v2Frame = _frames[ i ];
				result += frame.data.length + ID3v2Frame.HEADER_SIZE;
				
				i ++;
			}	
			
			return result;
		}
		
		public function getData() : ByteArray
		{
			var data : ByteArray = new ByteArray();
			
			if ( _frames.length > 0 )
			{
				var size : int = getFramesSize();
				
				data.writeMultiByte( ID3HEADER, 'iso-8859-1' ); //ID3
				data.writeByte( TAG_VERSION_2_3 ); //Version
				data.writeByte( 0 ); //Revision
				data.writeByte( 0 ); //Flags
				
				var i    : int = 1;
				
				while( i < 5 )//Size
				{
					data.writeByte( size >> ( ( 4 - i ) * 7 ) & 0x7F );
					i ++;
				}	
				
				i = 0;
				
				while( i < _frames.length )//frames
				{
					data.writeBytes( _frames[ i ].getData() );
					
					i ++;
				}	
				
			}
			
			_size = size + HEADER_SIZE;
			
			return data;	
		}	
			
		public function analyze( data : ByteArray ) : Boolean
		{
			if ( data.readUTFBytes( 3 ) == ID3HEADER )
			{
				_version  = data.readUnsignedByte();
				_revision = data.readUnsignedByte();
				
				//ID3v2 flags
				var d : int = data.readUnsignedByte();
				
				_unsynchronizationFlag = Boolean( d & 0x7F );
				_extendedHeaderFlag = Boolean( d & 0xBF );
				_experimentalFlag = Boolean( d & 0xDF );
				_footerPresent = Boolean( d & 0xEF );  
				
				_size = data.readUnsignedByte() * 0x200000 +
					    data.readUnsignedByte() * 0x4000 +
						data.readUnsignedByte() * 0x80 +
						data.readUnsignedByte() + HEADER_SIZE;
				
				if ( _version >= TAG_VERSION_2_3 )
				{
					var sizeWithoutHeader : int = _size - HEADER_SIZE;
					
					if ( _extendedHeaderFlag )
					{
						data.position += 10;
						sizeWithoutHeader -= 10;
					}
					
					while( data.position < sizeWithoutHeader  )
					{
						var frame : ID3v2Frame = new ID3v2Frame();
						
						if ( frame.analyze( data ) )
						{
							var textFrame : ID3v2TextFrame = new ID3v2TextFrame( frame );
							//trace( frame.id + ' = ' + textFrame.text );
							
							_frames.push( frame );
							
						}	
						else break;
					}	
				}	
				
				data.position = _size;
				
				return true;
			}
			
			return false;
		}
	}
}

	