package com.audioengine.format.mpeg.id3v2
{
	import flash.utils.ByteArray;

	public class ID3v2Frame
	{
		public static const HEADER_SIZE : int = 10;
		
		/**
		 * frame id 
		 */		
		private var _id   : String;
		/**
		 * data size without header size ( use data length instead !!!! ) 
		 */		
		//private var _size : int;
		/**
		 * FrameData 
		 */		
		private var _data : ByteArray;
		
		/**
		 * 
		 * Frame flags
		 * 
		 */
		/**
		 * not extracted flags 
		 */		
		private var _flags : int;
		/**
		 * Tag alter preservation

     This flag tells the tag parser what to do with this frame if it is
     unknown and the tag is altered in any way. This applies to all
     kinds of alterations, including adding more padding and reordering
     the frames.

     0     Frame should be preserved.
     1     Frame should be discarded.
		 */		
		private var _tagAlterPreservation : Boolean;
		/**
		 * File alter preservation

     This flag tells the tag parser what to do with this frame if it is
     unknown and the file, excluding the tag, is altered. This does not
     apply when the audio is completely replaced with other audio data.

     0     Frame should be preserved.
     1     Frame should be discarded. 
		 */		
		private var _fileAlterPreservation : Boolean;
		/**
		 * Read only

      This flag, if set, tells the software that the contents of this
      frame are intended to be read only. Changing the contents might
      break something, e.g. a signature. If the contents are changed,
      without knowledge of why the frame was flagged read only and
      without taking the proper means to compensate, e.g. recalculating
      the signature, the bit MUST be cleared.
		 */
		private var _readOnly : Boolean;
		/**
		 * Grouping identity

      This flag indicates whether or not this frame belongs in a group
      with other frames. If set, a group identifier byte is added to the
      frame. Every frame with the same group identifier belongs to the
      same group.

      0     Frame does not contain group information
      1     Frame contains group information
		 */		
		private var _groupingIdentity : Boolean;
		/**
		 * Compression

      This flag indicates whether or not the frame is compressed.
      A 'Data Length Indicator' byte MUST be included in the frame.

      0     Frame is not compressed.
      1     Frame is compressed using zlib [zlib] deflate method.
            If set, this requires the 'Data Length Indicator' bit
            to be set as well. 
		 */		
		private var _compression : Boolean;
		/**
		 * Encryption
   
      This flag indicates whether or not the frame is encrypted. If set,
      one byte indicating with which method it was encrypted will be
      added to the frame. See description of the ENCR frame for more
      information about encryption method registration. Encryption
      should be done after compression. Whether or not setting this flag
      requires the presence of a 'Data Length Indicator' depends on the
      specific algorithm used.

      0     Frame is not encrypted.
      1     Frame is encrypted. 
		 */		
		private var _encryption : Boolean;
		/**
		 * Unsynchronisation

      This flag indicates whether or not unsynchronisation was applied
      to this frame. See section 6 for details on unsynchronisation.
      If this flag is set all data from the end of this header to the
      end of this frame has been unsynchronised. Although desirable, the
      presence of a 'Data Length Indicator' is not made mandatory by
      unsynchronisation.

      0     Frame has not been unsynchronised.
      1     Frame has been unsyrchronised. 
		 */		
		private var _unsynchronization : Boolean;
		/**
		 * Data length indicator

      This flag indicates that a data length indicator has been added to
      the frame. The data length indicator is the value one would write
      as the 'Frame length' if all of the frame format flags were
      zeroed, represented as a 32 bit synchsafe integer.

      0      There is no Data Length Indicator.
      1      A data length Indicator has been added to the frame.
		 */		
		private var _dataLengthIndicator : Boolean;
		
		public function ID3v2Frame( id : String = null )
		{
			super();
			
			_data = new ByteArray();
			_id   = id;
		}
		
		public function getData() : ByteArray
		{
			var data : ByteArray = new ByteArray();
			
			data.writeMultiByte( _id, 'iso-8859-1' ); //Frame ID
			data.writeInt( _data.length ); //Size
			data.writeShort( 0 ); //Flags
			data.writeBytes( _data ); //data
			
			return data;
		}	
		
		/**
		 *  
		 * @return frame data 
		 * 
		 */		
		public function get data() : ByteArray
		{
			return _data;
		}
		
		public function get id() : String
		{
			return _id;
		}
		
		public function analyze( data : ByteArray ) : Boolean
		{
			var _size : int;
			
			_id = data.readUTFBytes( 4 );
			
			if ( _id.length == 4 )
			{
				_size = data.readUnsignedInt();
				
				if ( _size < data.bytesAvailable )
				{
					_flags = data.readUnsignedShort();
					extractFlags( _flags );
					
					data.readBytes( _data, 0, _size );
					
					return true;
				}	
			}	
			
			return false;
		}
		
		private function extractFlags( flags : int ) : void
		{
			//%0abc0000 %0h00kmnp
			
			_tagAlterPreservation  = Boolean( flags & 0xBFFFF );
			_fileAlterPreservation = Boolean( flags & 0xDFFFF );
			_readOnly              = Boolean( flags & 0xEFFFF );
			_groupingIdentity      = Boolean( flags & 0xFFBF );
			_compression           = Boolean( flags & 0xFFF7 );
			_encryption            = Boolean( flags & 0xFFFB );
			_unsynchronization     = Boolean( flags & 0xFFFD );
			_dataLengthIndicator   = Boolean( flags & 0xFFFE );
		}	
	}
}