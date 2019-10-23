package com.audioengine.format.mpeg
{
	import flash.utils.ByteArray;

	public class VBRFrame
	{
		/**
		 *  VBR header ID for Xing/FhG
		 */
		
		/**
		 *Xing VBR ID 
		 */		
		public static const VBR_ID_XING : String = 'Xing';                                         
		
		/**
		 * FhG VBR ID 
		 */		
		public static const VBR_ID_FHG : String = 'VBRI';
		
		private var _id       : String;
		private var _flags    : int;
		private var _frames   : int;
		private var _bytes    : int;
		private var _scale    : int;
		private var _vendorID : String;
		
		public function VBRFrame()
		{
		}
		
		public function analyze( data : ByteArray ) : Boolean
		{
			//Check for VBR header
			var id : String = data.readUTFBytes( 4 );
			
			if ( id == VBR_ID_XING )
			{
				getXingInfo( data );
			}
			else if ( id == VBR_ID_FHG )
			{
			  getFhGInfo( data );	
			}
			else return false;
			
			return true;
		}
		
		/**
		 * { Extract Xing VBR info } 
		 * 
		 */		
		private function getXingInfo( data : ByteArray ) : void
		{
		  _id     = VBR_ID_XING;
		  _flags  = data.readUnsignedInt();
		  
		  _frames = data.readUnsignedByte() * 0x1000000 +
			        data.readUnsignedByte() * 0x10000 +
			        data.readUnsignedByte() * 0x100 +
			        data.readUnsignedByte();
		  
		  _bytes = data.readUnsignedByte() * 0x1000000 +
			       data.readUnsignedByte() * 0x10000 +
				   data.readUnsignedByte() * 0x100 +
				   data.readUnsignedByte();
		  
		  data.position += 103;
		  
		  _scale = data.readUnsignedByte();
		  _vendorID = data.readUTFBytes( 8 );
		}
		
		private function getFhGInfo( data : ByteArray ) : void
		{
			
		}	
		
		
		
		/**
		 * { Get true if Xing encoder } 
		 * @param data
		 * @return 
		 * 
		 */		
		public static function isXing( data : ByteArray ) : Boolean
		{
			var i      : int = 0;
			
			while( i < 6 )
			{
				if ( data.readUnsignedByte() != 0 )
					return false;
				
				i ++;
			}
			
			return true;
		}
	}
}